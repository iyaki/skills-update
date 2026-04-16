#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SMOKE_WORKFLOW="$ROOT_DIR/.github/workflows/smoke-marketplace-action.yml"
RELEASE_WORKFLOW="$ROOT_DIR/.github/workflows/release-marketplace-action.yml"

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

echo "Marketplace workflow checks passed"
