#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
RUNTIME_SCRIPT="$ROOT_DIR/scripts/run-skill-update.sh"

fail() {
	echo "Error: $*" >&2
	exit 1
}

assert_eq() {
	local actual="$1"
	local expected="$2"
	local message="$3"
	if [[ "$actual" != "$expected" ]]; then
		fail "$message (expected '$expected', got '$actual')"
	fi
}

assert_non_empty() {
	local value="$1"
	local message="$2"
	if [[ -z "$value" ]]; then
		fail "$message"
	fi
}

assert_contains_line() {
	local needle="$1"
	local file="$2"
	if ! grep -Fxq "$needle" "$file"; then
		fail "Expected output line '$needle' in $file"
	fi
}

setup_repo() {
	local dir="$1"
	git init -q "$dir"
	git -C "$dir" config user.name "Skills Bot"
	git -C "$dir" config user.email "skills-bot@example.com"
	printf "{}\n" >"$dir/skills-lock.json"
	mkdir -p "$dir/.agents"
	printf "{}\n" >"$dir/.agents/.skill-lock.json"
	printf "# sample\n" >"$dir/README.md"
	git -C "$dir" add .
	git -C "$dir" commit -q -m "chore: seed fixtures"
}

run_runtime() {
	local repo_dir="$1"
	local update_command="$2"
	local create_commit="$3"
	local create_pr="$4"
	local output_file="$5"

	(
		cd "$ROOT_DIR"
		GITHUB_OUTPUT="$output_file" \
			GITHUB_TOKEN="test-token" \
			GITHUB_REPOSITORY="octo/example" \
			INPUT_WORKING_DIRECTORY="$repo_dir" \
			INPUT_SKILLS_CLI_VERSION="0.11.0" \
			INPUT_UPDATE_COMMAND="$update_command" \
			INPUT_ADD_PATHS="skills-lock.json,.agents/skills/**" \
			INPUT_IGNORE_PATHS=".agents/.skill-lock.json" \
			INPUT_CREATE_COMMIT="$create_commit" \
			INPUT_COMMIT_MESSAGE="chore(skills): update installed skills" \
			INPUT_CREATE_PR="$create_pr" \
			INPUT_PR_GENERATE_COMMIT="true" \
			INPUT_BASE_BRANCH="" \
			INPUT_PR_BRANCH="chore/skills-update" \
			INPUT_PR_TITLE="chore(skills): update installed skills" \
			INPUT_PR_LABELS="chore,automation" \
			bash "$RUNTIME_SCRIPT"
	)
}

test_no_change_skips_write_stages() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime "$workdir" "true" "true" "false" "$outputs"

	assert_contains_line "changed=false" "$outputs"
	assert_contains_line "commit-created=false" "$outputs"
	assert_contains_line "pull-request-number=" "$outputs"
	assert_contains_line "pull-request-url=" "$outputs"
}

test_allowed_change_creates_commit() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime "$workdir" "bash -lc 'printf \"{\\\"updated\\\":true}\\n\" > skills-lock.json'" "true" "false" "$outputs"

	assert_contains_line "changed=true" "$outputs"
	assert_contains_line "updated-files<<__SKILLS_EOF__" "$outputs"
	assert_contains_line "skills-lock.json" "$outputs"

	local commit_created
	commit_created=$(grep -E '^commit-created=' "$outputs" | cut -d= -f2)
	assert_eq "$commit_created" "true" "Commit stage should run for allowlisted changes"

	local commit_sha
	commit_sha=$(grep -E '^commit-sha=' "$outputs" | cut -d= -f2)
	assert_non_empty "$commit_sha" "Commit SHA must be present when commit is created"
	[[ "$commit_sha" =~ ^[0-9a-f]{40}$ ]] || fail "Commit SHA should be 40 lowercase hex characters"
}

test_blocked_path_fails() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	set +e
	run_runtime "$workdir" "bash -lc 'printf \"changed\\n\" >> README.md'" "true" "false" "$outputs"
	local exit_code=$?
	set -e

	if [[ "$exit_code" -eq 0 ]]; then
		fail "Runtime should fail when blocked paths are modified"
	fi
}

test_ignored_only_change_is_non_failing() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime "$workdir" "bash -lc 'printf \"{\\\"local\\\":true}\\n\" > .agents/.skill-lock.json'" "true" "false" "$outputs"

	assert_contains_line "changed=false" "$outputs"
	assert_contains_line "commit-created=false" "$outputs"
}

main() {
	[[ -x "$RUNTIME_SCRIPT" ]] || fail "Runtime script not executable: $RUNTIME_SCRIPT"

	test_no_change_skips_write_stages
	test_allowed_change_creates_commit
	test_blocked_path_fails
	test_ignored_only_change_is_non_failing

	echo "Runtime orchestration tests passed"
}

main "$@"
