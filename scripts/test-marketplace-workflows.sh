#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SMOKE_WORKFLOW="$ROOT_DIR/.github/workflows/smoke-marketplace-action.yml"
RELEASE_WORKFLOW="$ROOT_DIR/.github/workflows/release-marketplace-action.yml"
SECURITY_WORKFLOW="$ROOT_DIR/.github/workflows/security.yml"
DEPENDABOT_AUTOMERGE_WORKFLOW="$ROOT_DIR/.github/workflows/dependabot-automerge.yml"
README_FILE="$ROOT_DIR/README.md"

fail() {
	echo "Error: $*" >&2
	exit 1
}

assert_contains() {
	local needle="$1"
	local file="$2"
	if ! grep -Fq -- "$needle" "$file"; then
		fail "Expected '$needle' in $file"
	fi
}

[[ -f "$SMOKE_WORKFLOW" ]] || fail "Missing smoke workflow: $SMOKE_WORKFLOW"
[[ -f "$RELEASE_WORKFLOW" ]] || fail "Missing release workflow: $RELEASE_WORKFLOW"
[[ -f "$SECURITY_WORKFLOW" ]] || fail "Missing security workflow: $SECURITY_WORKFLOW"
[[ -f "$DEPENDABOT_AUTOMERGE_WORKFLOW" ]] || fail "Missing dependabot automerge workflow: $DEPENDABOT_AUTOMERGE_WORKFLOW"
[[ -f "$README_FILE" ]] || fail "Missing README: $README_FILE"

assert_contains "name: smoke marketplace action" "$SMOKE_WORKFLOW"
assert_contains "workflow_dispatch:" "$SMOKE_WORKFLOW"
assert_contains "scenario:" "$SMOKE_WORKFLOW"
assert_contains "- update-only" "$SMOKE_WORKFLOW"
assert_contains "- commit-enabled" "$SMOKE_WORKFLOW"
assert_contains "- pr-enabled" "$SMOKE_WORKFLOW"
assert_contains "bash scripts/test-run-skill-update.sh" "$SMOKE_WORKFLOW"

assert_contains "name: release marketplace action" "$RELEASE_WORKFLOW"
assert_contains "workflow_dispatch:" "$RELEASE_WORKFLOW"
assert_contains "release-tag" "$RELEASE_WORKFLOW"
assert_contains "uses: actions/checkout@v6" "$RELEASE_WORKFLOW"
assert_contains "bash scripts/test-run-skill-update.sh" "$RELEASE_WORKFLOW"
assert_contains "git tag \"\$release_tag\"" "$RELEASE_WORKFLOW"

assert_contains "name: quality" "$SECURITY_WORKFLOW"
assert_contains "workflow_dispatch:" "$SECURITY_WORKFLOW"
assert_contains "jobs:" "$SECURITY_WORKFLOW"
assert_contains "semgrep:" "$SECURITY_WORKFLOW"
assert_contains "name: Checkout repository" "$SECURITY_WORKFLOW"
assert_contains "uses: actions/checkout@v6" "$SECURITY_WORKFLOW"
assert_contains "run: semgrep ci" "$SECURITY_WORKFLOW"

assert_contains "name: auto-merge dependencies" "$DEPENDABOT_AUTOMERGE_WORKFLOW"
assert_contains "name: Auto-merge Dependabot PRs" "$DEPENDABOT_AUTOMERGE_WORKFLOW"
assert_contains "uses: fastify/github-action-merge-dependabot@v3.12.0" "$DEPENDABOT_AUTOMERGE_WORKFLOW"

assert_contains "Verification and diagnostics:" "$README_FILE"
assert_contains "gh run view <run-id> --log-failed" "$README_FILE"

echo "Marketplace workflow checks passed"
