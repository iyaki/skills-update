#!/usr/bin/env bash
set -euo pipefail

fail() {
	echo "Error: $*" >&2
	exit 1
}

trim() {
	local value="$1"
	value="${value#${value%%[![:space:]]*}}"
	value="${value%${value##*[![:space:]]}}"
	printf '%s' "$value"
}

to_bool() {
	local value
	value=$(trim "$1")
	case "$value" in
	true | TRUE | True | 1 | yes | YES | on | ON) echo "true" ;;
	false | FALSE | False | 0 | no | NO | off | OFF | "") echo "false" ;;
	*) fail "Invalid boolean value: '$1'" ;;
	esac
}

csv_to_array() {
	local csv="$1"
	local -n output_ref="$2"
	output_ref=()

	local item
	IFS=',' read -r -a raw_items <<<"$csv"
	for item in "${raw_items[@]}"; do
		item=$(trim "$item")
		if [[ -n "$item" ]]; then
			output_ref+=("$item")
		fi
	done
}

matches_any_glob() {
	local path="$1"
	shift
	local pattern
	for pattern in "$@"; do
		if [[ "$path" == $pattern ]]; then
			return 0
		fi
	done
	return 1
}

write_output() {
	local key="$1"
	local value="$2"
	local output_file="${GITHUB_OUTPUT:-}"

	if [[ -n "$output_file" ]]; then
		printf '%s=%s\n' "$key" "$value" >>"$output_file"
	else
		printf '%s=%s\n' "$key" "$value"
	fi
}

write_multiline_output() {
	local key="$1"
	local value="$2"
	local output_file="${GITHUB_OUTPUT:-}"
	local marker="__SKILLS_EOF__"

	if [[ -n "$output_file" ]]; then
		{
			printf '%s<<%s\n' "$key" "$marker"
			printf '%s\n' "$value"
			printf '%s\n' "$marker"
		} >>"$output_file"
	else
		printf '%s=%s\n' "$key" "$value"
	fi
}

ensure_inside_repo() {
	git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "working-directory must be inside a git repository"
}

resolve_branch_output() {
	local create_pr="$1"
	local pr_branch="$2"

	if [[ "$create_pr" == "true" ]]; then
		printf '%s' "$pr_branch"
		return
	fi

	git rev-parse --abbrev-ref HEAD 2>/dev/null || printf '%s' ""
}

collect_changed_files() {
	local -n out_ref="$1"
	mapfile -t out_ref < <(
		{
			git diff --name-only
			git diff --name-only --cached
			git ls-files --others --exclude-standard
		} | sed '/^$/d' | sort -u
	)
}

stage_allowed_files() {
	local -n files_ref="$1"
	if [[ "${#files_ref[@]}" -eq 0 ]]; then
		return
	fi
	git add -- "${files_ref[@]}"
}

create_commit_from_allowed() {
	local commit_message="$1"
	local -n allowed_ref="$2"

	stage_allowed_files allowed_ref
	if git diff --cached --quiet; then
		fail "No staged files found for commit creation"
	fi

	git commit -m "$commit_message" >/dev/null
	git rev-parse HEAD
}

main() {
	local working_directory="${INPUT_WORKING_DIRECTORY:-.}"
	local update_command="${INPUT_UPDATE_COMMAND:-}"
	local add_paths_csv="${INPUT_ADD_PATHS:-skills-lock.json,.agents/skills/**}"
	local ignore_paths_csv="${INPUT_IGNORE_PATHS:-.agents/.skill-lock.json}"
	local create_commit
	create_commit=$(to_bool "${INPUT_CREATE_COMMIT:-true}")
	local commit_message="${INPUT_COMMIT_MESSAGE:-chore(skills): update installed skills}"
	local create_pr
	create_pr=$(to_bool "${INPUT_CREATE_PR:-true}")
	local pr_generate_commit
	pr_generate_commit=$(to_bool "${INPUT_PR_GENERATE_COMMIT:-true}")
	local pr_branch="${INPUT_PR_BRANCH:-chore/skills-update}"

	[[ -n "$update_command" ]] || fail "update-command is required"
	[[ -d "$working_directory" ]] || fail "working-directory does not exist: $working_directory"

	local -a add_paths=()
	local -a ignore_paths=()
	csv_to_array "$add_paths_csv" add_paths
	csv_to_array "$ignore_paths_csv" ignore_paths
	[[ "${#add_paths[@]}" -gt 0 ]] || fail "add-paths cannot be empty"

	cd "$working_directory"
	ensure_inside_repo

	local branch
	branch=$(resolve_branch_output "$create_pr" "$pr_branch")

	if ! bash -lc "$update_command"; then
		fail "update stage failed while executing update-command"
	fi

	local -a changed_files=()
	local -a allowed_files=()
	local -a blocked_files=()
	local file
	collect_changed_files changed_files

	for file in "${changed_files[@]}"; do
		if matches_any_glob "$file" "${ignore_paths[@]}"; then
			continue
		fi
		if matches_any_glob "$file" "${add_paths[@]}"; then
			allowed_files+=("$file")
		else
			blocked_files+=("$file")
		fi
	done

	if [[ "${#blocked_files[@]}" -gt 0 ]]; then
		printf 'Blocked path changes detected:\n' >&2
		printf ' - %s\n' "${blocked_files[@]}" >&2
		fail "update stage failed due to blocked path changes"
	fi

	local changed="false"
	local updated_files=""
	if [[ "${#allowed_files[@]}" -gt 0 ]]; then
		changed="true"
		updated_files=$(printf '%s\n' "${allowed_files[@]}")
		updated_files="${updated_files%$'\n'}"
	fi

	local commit_created="false"
	local commit_sha=""
	if [[ "$changed" == "true" && "$create_commit" == "true" ]]; then
		commit_sha=$(create_commit_from_allowed "$commit_message" allowed_files)
		commit_created="true"
	fi

	local pull_request_number=""
	local pull_request_url=""
	if [[ "$changed" == "true" && "$create_pr" == "true" ]]; then
		if [[ -z "$commit_sha" ]]; then
			if [[ "$pr_generate_commit" == "true" ]]; then
				commit_sha=$(create_commit_from_allowed "$commit_message" allowed_files)
				commit_created="true"
			else
				fail "pull request stage requires commit, but pr-generate-commit=false and no commit exists"
			fi
		fi
		fail "pull request stage is not implemented yet"
	fi

	write_output "changed" "$changed"
	write_multiline_output "updated-files" "$updated_files"
	write_output "commit-created" "$commit_created"
	write_output "commit-sha" "$commit_sha"
	write_output "pull-request-number" "$pull_request_number"
	write_output "pull-request-url" "$pull_request_url"
	write_output "branch" "$branch"
}

main "$@"
