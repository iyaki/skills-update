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

json_extract() {
	local python_expr="$1"
	python -c "import json,sys; data=json.load(sys.stdin); result=($python_expr); print('' if result is None else result)"
}

resolve_base_branch() {
	local repository="$1"
	local configured_base_branch="$2"

	if [[ -n "$configured_base_branch" ]]; then
		printf '%s' "$configured_base_branch"
		return
	fi

	gh api "repos/${repository}" | json_extract "data.get('default_branch', '')"
}

checkout_pr_branch() {
	local pr_branch="$1"
	local current_branch
	current_branch=$(git rev-parse --abbrev-ref HEAD)

	if [[ "$current_branch" != "$pr_branch" ]]; then
		git checkout -B "$pr_branch" >/dev/null
	fi
}

push_pr_branch() {
	local pr_branch="$1"
	git push -u origin "HEAD:${pr_branch}" >/dev/null
}

find_existing_pr_json() {
	local repository="$1"
	local owner="$2"
	local pr_branch="$3"
	local base_branch="$4"
	gh api "repos/${repository}/pulls?state=open&head=${owner}:${pr_branch}&base=${base_branch}&per_page=1"
}

create_pr_json() {
	local repository="$1"
	local base_branch="$2"
	local pr_branch="$3"
	local pr_title="$4"
	gh api -X POST "repos/${repository}/pulls" -f "title=${pr_title}" -f "head=${pr_branch}" -f "base=${base_branch}"
}

add_pr_labels() {
	local repository="$1"
	local pr_number="$2"
	local -n labels_ref="$3"

	if [[ "${#labels_ref[@]}" -eq 0 ]]; then
		return
	fi

	local -a args=()
	local label
	for label in "${labels_ref[@]}"; do
		args+=("-f" "labels[]=${label}")
	done

	gh api -X POST "repos/${repository}/issues/${pr_number}/labels" "${args[@]}" >/dev/null
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
	local base_branch_input="${INPUT_BASE_BRANCH:-}"
	local pr_branch="${INPUT_PR_BRANCH:-chore/skills-update}"
	local pr_title="${INPUT_PR_TITLE:-chore(skills): update installed skills}"
	local pr_labels_csv="${INPUT_PR_LABELS:-chore,automation}"

	[[ -n "$update_command" ]] || fail "update-command is required"
	[[ -d "$working_directory" ]] || fail "working-directory does not exist: $working_directory"

	local -a add_paths=()
	local -a ignore_paths=()
	local -a pr_labels=()
	csv_to_array "$add_paths_csv" add_paths
	csv_to_array "$ignore_paths_csv" ignore_paths
	csv_to_array "$pr_labels_csv" pr_labels
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
		local github_repository="${GITHUB_REPOSITORY:-}"
		[[ -n "$github_repository" ]] || fail "GITHUB_REPOSITORY is required when create-pr=true"
		command -v gh >/dev/null 2>&1 || fail "gh CLI is required when create-pr=true"

		if [[ -z "$commit_sha" ]]; then
			if [[ "$pr_generate_commit" == "true" ]]; then
				commit_sha=$(create_commit_from_allowed "$commit_message" allowed_files)
				commit_created="true"
			else
				fail "pull request stage requires commit, but pr-generate-commit=false and no commit exists"
			fi
		fi

		checkout_pr_branch "$pr_branch"
		push_pr_branch "$pr_branch"

		local owner="${github_repository%%/*}"
		local base_branch
		base_branch=$(resolve_base_branch "$github_repository" "$base_branch_input")
		[[ -n "$base_branch" ]] || fail "Unable to resolve base branch for pull request stage"

		local existing_pr_json
		existing_pr_json=$(find_existing_pr_json "$github_repository" "$owner" "$pr_branch" "$base_branch")
		local existing_pr_number
		existing_pr_number=$(printf '%s' "$existing_pr_json" | json_extract "str(data[0].get('number')) if isinstance(data, list) and len(data) > 0 else ''")

		if [[ -n "$existing_pr_number" ]]; then
			pull_request_number="$existing_pr_number"
			pull_request_url=$(printf '%s' "$existing_pr_json" | json_extract "data[0].get('html_url', '') if isinstance(data, list) and len(data) > 0 else ''")
		else
			local created_pr_json
			created_pr_json=$(create_pr_json "$github_repository" "$base_branch" "$pr_branch" "$pr_title")
			pull_request_number=$(printf '%s' "$created_pr_json" | json_extract "str(data.get('number', ''))")
			pull_request_url=$(printf '%s' "$created_pr_json" | json_extract "data.get('html_url', '')")
		fi

		[[ -n "$pull_request_number" ]] || fail "pull request stage failed to produce pull request number"
		[[ -n "$pull_request_url" ]] || fail "pull request stage failed to produce pull request URL"
		add_pr_labels "$github_repository" "$pull_request_number" pr_labels
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
