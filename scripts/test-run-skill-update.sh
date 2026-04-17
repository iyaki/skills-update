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

assert_contains_text() {
	local needle="$1"
	local file="$2"
	if ! grep -Fq "$needle" "$file"; then
		fail "Expected output text '$needle' in $file"
	fi
}

assert_not_contains_key() {
	local key="$1"
	local file="$2"
	if grep -Eq "^${key}=" "$file"; then
		fail "Did not expect output key '$key' in $file"
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
	local pr_generate_commit="$5"
	local output_file="$6"
	local path_prefix="${7:-}"
	local commit_message="${8:-chore(skills): update installed skills}"
	local add_paths="${9:-skills-lock.json,.agents/skills/**}"
	local ignore_paths="${10:-.agents/.skill-lock.json}"

	(
		cd "$ROOT_DIR"
		local runtime_path="$PATH"
		if [[ -n "$path_prefix" ]]; then
			runtime_path="$path_prefix:$runtime_path"
		fi
		GITHUB_OUTPUT="$output_file" \
			GITHUB_TOKEN="test-token" \
			PATH="$runtime_path" \
			GITHUB_REPOSITORY="octo/example" \
			INPUT_WORKING_DIRECTORY="$repo_dir" \
			INPUT_SKILLS_CLI_VERSION="latest" \
			INPUT_UPDATE_COMMAND="$update_command" \
			INPUT_ADD_PATHS="$add_paths" \
			INPUT_IGNORE_PATHS="$ignore_paths" \
			INPUT_CREATE_COMMIT="$create_commit" \
			INPUT_COMMIT_MESSAGE="$commit_message" \
			INPUT_CREATE_PR="$create_pr" \
			INPUT_PR_GENERATE_COMMIT="$pr_generate_commit" \
			INPUT_BASE_BRANCH="" \
			INPUT_PR_BRANCH="chore/skills-update" \
			INPUT_PR_TITLE="chore(skills): update installed skills" \
			INPUT_PR_LABELS="chore,automation" \
			bash "$RUNTIME_SCRIPT"
	)
}

test_add_paths_normalizes_dot_slash_prefix() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime \
		"$workdir" \
		"bash -lc 'printf \"{\\\"updated\\\":true}\\n\" > skills-lock.json'" \
		"true" \
		"false" \
		"true" \
		"$outputs" \
		"" \
		"chore(skills): update installed skills" \
		"./skills-lock.json,./.agents/skills/**"

	assert_contains_line "changed=true" "$outputs"
	assert_contains_line "commit-created=true" "$outputs"
}

test_rejects_path_traversal_in_policy_inputs() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	local stdout_file
	stdout_file=$(mktemp)
	local stderr_file
	stderr_file=$(mktemp)
	setup_repo "$workdir"

	set +e
	run_runtime \
		"$workdir" \
		"true" \
		"false" \
		"false" \
		"true" \
		"$outputs" \
		"" \
		"chore(skills): update installed skills" \
		"../skills-lock.json,.agents/skills/**" \
		>"$stdout_file" 2>"$stderr_file"
	local exit_code=$?
	set -e

	if [[ "$exit_code" -eq 0 ]]; then
		fail "Runtime should fail when add-paths contains path traversal patterns"
	fi

	assert_contains_text "Path policy entries must not contain path traversal segments" "$stderr_file"
}

setup_origin_remote() {
	local repo_dir="$1"
	local remote_dir
	remote_dir=$(mktemp -d)
	git init --bare -q "$remote_dir/origin.git"
	git -C "$repo_dir" remote add origin "$remote_dir/origin.git"
	git -C "$repo_dir" push -q -u origin HEAD:main
}

setup_fake_gh() {
	local bin_dir="$1"
	mkdir -p "$bin_dir"
	cat >"$bin_dir/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

method="GET"
endpoint=""

if [[ "$1" != "api" ]]; then
	echo "unsupported gh command" >&2
	exit 1
fi
shift

while [[ "$#" -gt 0 ]]; do
	case "$1" in
	-X)
		method="$2"
		shift 2
		;;
	-f)
		shift 2
		;;
	*)
		if [[ -z "$endpoint" ]]; then
			endpoint="$1"
		fi
		shift
		;;
	esac
done

case "$method:$endpoint" in
"GET:repos/octo/example")
	printf '{"default_branch":"main"}\n'
	;;
"GET:repos/octo/example/pulls?state=open&head=octo:chore/skills-update&base=main&per_page=1")
	printf '[]\n'
	;;
"POST:repos/octo/example/pulls")
	printf '{"number":7,"html_url":"https://github.com/octo/example/pull/7"}\n'
	;;
"POST:repos/octo/example/issues/7/labels")
	printf '{"ok":true}\n'
	;;
*)
	echo "unsupported api call: $method $endpoint" >&2
	exit 1
	;;
esac
EOF
	chmod +x "$bin_dir/gh"
}

setup_fake_npx() {
	local bin_dir="$1"
	local expected_version="$2"
	mkdir -p "$bin_dir"
	cat >"$bin_dir/npx" <<EOF
#!/usr/bin/env bash
set -euo pipefail

if [[ "\$1" != "--yes" ]]; then
	echo "missing --yes" >&2
	exit 1
fi

if [[ "\$2" != "skills@${expected_version}" ]]; then
	echo "unexpected skills version: \$2" >&2
	exit 1
fi

case "\${3:-}" in
experimental_install)
	if [[ "\${4:-}" != "-y" ]]; then
		echo "unexpected update command args" >&2
		exit 1
	fi
	;;
update)
	if [[ "\${4:-}" != "-p" || "\${5:-}" != "-y" ]]; then
		echo "unexpected update command args" >&2
		exit 1
	fi
	;;
*)
	echo "unexpected update command args" >&2
	exit 1
	;;
esac

printf '{"updated":true}\n' > skills-lock.json
EOF
	chmod +x "$bin_dir/npx"
}

test_no_change_skips_write_stages() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime "$workdir" "true" "true" "false" "true" "$outputs"

	assert_contains_line "changed=false" "$outputs"
	assert_contains_line "commit-created=false" "$outputs"
	assert_not_contains_key "commit-sha" "$outputs"
	assert_not_contains_key "pull-request-number" "$outputs"
	assert_not_contains_key "pull-request-url" "$outputs"
}

test_allowed_change_creates_commit() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime "$workdir" "bash -lc 'printf \"{\\\"updated\\\":true}\\n\" > skills-lock.json'" "true" "false" "true" "$outputs"

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

test_create_commit_disabled_skips_commit_with_allowed_changes() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime "$workdir" "bash -lc 'printf \"{\\\"updated\\\":true}\\n\" > skills-lock.json'" "false" "false" "true" "$outputs"

	assert_contains_line "changed=true" "$outputs"
	assert_contains_line "commit-created=false" "$outputs"
	assert_not_contains_key "commit-sha" "$outputs"

	local commit_count
	commit_count=$(git -C "$workdir" rev-list --count HEAD)
	assert_eq "$commit_count" "1" "Commit stage must be skipped when create-commit=false"
}

test_commit_excludes_pre_staged_ignored_files() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	printf '{"ignored":true}\n' >"$workdir/.agents/.skill-lock.json"
	git -C "$workdir" add .agents/.skill-lock.json

	run_runtime "$workdir" "bash -lc 'printf \"{\\\"updated\\\":true}\\n\" > skills-lock.json'" "true" "false" "true" "$outputs"

	assert_contains_line "changed=true" "$outputs"
	assert_contains_line "commit-created=true" "$outputs"

	local commit_sha
	commit_sha=$(grep -E '^commit-sha=' "$outputs" | cut -d= -f2)
	assert_non_empty "$commit_sha" "Commit SHA must be present when commit is created"

	local committed_files
	committed_files=$(git -C "$workdir" show --name-only --pretty=format: "$commit_sha")
	if grep -Fxq ".agents/.skill-lock.json" <<<"$committed_files"; then
		fail "Commit must not include ignored files"
	fi
	if ! grep -Fxq "skills-lock.json" <<<"$committed_files"; then
		fail "Commit should include allowlisted updated files"
	fi
}

test_blocked_path_fails() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	local stdout_file
	stdout_file=$(mktemp)
	local stderr_file
	stderr_file=$(mktemp)
	setup_repo "$workdir"

	set +e
	run_runtime "$workdir" "bash -lc 'printf \"changed\\n\" >> README.md'" "true" "false" "true" "$outputs" >"$stdout_file" 2>"$stderr_file"
	local exit_code=$?
	set -e

	if [[ "$exit_code" -eq 0 ]]; then
		fail "Runtime should fail when blocked paths are modified"
	fi

	assert_contains_text "Blocked path changes detected:" "$stderr_file"
	assert_contains_text "update stage failed due to blocked path changes" "$stderr_file"
}

test_ignored_only_change_is_non_failing() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime "$workdir" "bash -lc 'printf \"{\\\"local\\\":true}\\n\" > .agents/.skill-lock.json'" "true" "false" "true" "$outputs"

	assert_contains_line "changed=false" "$outputs"
	assert_contains_line "commit-created=false" "$outputs"
}

test_pr_stage_creates_pr_and_emits_outputs() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	local fake_tools
	fake_tools=$(mktemp -d)
	local fake_bin="$fake_tools/fake-bin"
	setup_repo "$workdir"
	setup_origin_remote "$workdir"
	setup_fake_gh "$fake_bin"

	run_runtime "$workdir" "bash -lc 'printf \"{\\\"updated\\\":true}\\n\" > skills-lock.json'" "false" "true" "true" "$outputs" "$fake_bin"

	assert_contains_line "changed=true" "$outputs"
	assert_contains_line "commit-created=true" "$outputs"
	assert_contains_line "pull-request-number=7" "$outputs"
	assert_contains_line "pull-request-url=https://github.com/octo/example/pull/7" "$outputs"

	local branch
	branch=$(grep -E '^branch=' "$outputs" | cut -d= -f2)
	assert_eq "$branch" "chore/skills-update" "Branch output should equal PR branch when PR stage is enabled"
}

test_pr_stage_fails_without_commit_when_generation_disabled() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	local stdout_file
	stdout_file=$(mktemp)
	local stderr_file
	stderr_file=$(mktemp)
	setup_repo "$workdir"

	set +e
	run_runtime "$workdir" "bash -lc 'printf \"{\\\"updated\\\":true}\\n\" > skills-lock.json'" "false" "true" "false" "$outputs" >"$stdout_file" 2>"$stderr_file"
	local exit_code=$?
	set -e

	if [[ "$exit_code" -eq 0 ]]; then
		fail "Runtime should fail when pull request stage cannot create missing commit"
	fi

	assert_contains_text "pull request stage requires commit" "$stderr_file"
}

test_default_update_command_uses_skills_cli_version() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	local fake_tools
	fake_tools=$(mktemp -d)
	local fake_bin="$fake_tools/fake-bin"
	setup_repo "$workdir"
	setup_fake_npx "$fake_bin" "9.9.9"

	(
		cd "$ROOT_DIR"
		GITHUB_OUTPUT="$outputs" \
			GITHUB_TOKEN="test-token" \
			PATH="$fake_bin:$PATH" \
			INPUT_WORKING_DIRECTORY="$workdir" \
			INPUT_SKILLS_CLI_VERSION="9.9.9" \
			INPUT_UPDATE_COMMAND="" \
			INPUT_ADD_PATHS="skills-lock.json,.agents/skills/**" \
			INPUT_IGNORE_PATHS=".agents/.skill-lock.json" \
			INPUT_CREATE_COMMIT="false" \
			INPUT_COMMIT_MESSAGE="chore(skills): update installed skills" \
			INPUT_CREATE_PR="false" \
			INPUT_PR_GENERATE_COMMIT="true" \
			INPUT_BASE_BRANCH="" \
			INPUT_PR_BRANCH="chore/skills-update" \
			INPUT_PR_TITLE="chore(skills): update installed skills" \
			INPUT_PR_LABELS="chore,automation" \
			bash "$RUNTIME_SCRIPT"
	)

	assert_contains_line "changed=true" "$outputs"
	assert_contains_line "updated-files<<__SKILLS_EOF__" "$outputs"
	assert_contains_line "skills-lock.json" "$outputs"
}

test_commit_message_is_configurable() {
	local workdir
	workdir=$(mktemp -d)
	local outputs="$workdir/outputs.txt"
	setup_repo "$workdir"

	run_runtime "$workdir" "bash -lc 'printf \"{\\\"updated\\\":true}\\n\" > skills-lock.json'" "true" "false" "true" "$outputs" "" "chore(skills): custom message"

	assert_contains_line "changed=true" "$outputs"
	assert_contains_line "commit-created=true" "$outputs"

	local latest_message
	latest_message=$(git -C "$workdir" log -1 --pretty=%s)
	assert_eq "$latest_message" "chore(skills): custom message" "Commit stage should use provided commit message"
}

main() {
	[[ -x "$RUNTIME_SCRIPT" ]] || fail "Runtime script not executable: $RUNTIME_SCRIPT"

	test_no_change_skips_write_stages
	test_add_paths_normalizes_dot_slash_prefix
	test_rejects_path_traversal_in_policy_inputs
	test_allowed_change_creates_commit
	test_create_commit_disabled_skips_commit_with_allowed_changes
	test_commit_excludes_pre_staged_ignored_files
	test_blocked_path_fails
	test_ignored_only_change_is_non_failing
	test_pr_stage_creates_pr_and_emits_outputs
	test_pr_stage_fails_without_commit_when_generation_disabled
	test_default_update_command_uses_skills_cli_version
	test_commit_message_is_configurable

	echo "Runtime orchestration tests passed"
}

main "$@"
