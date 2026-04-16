#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

usage() {
	cat <<'EOF'
Usage:
  scripts/test-template-stack.sh STACK

Arguments:
  STACK    Template stack to smoke test (go, javascript, php).
EOF
}

fail() {
	echo "Error: $*" >&2
	exit 1
}

require_file() {
	local path="$1"
	[[ -f "$path" ]] || fail "Expected file was not generated: $path"
}

setup_stack() {
	local stack="$1"
	local target_dir="$2"
	"$ROOT_DIR/scripts/stack-setup.sh" "$stack" --target "$target_dir" --force >/dev/null
}

smoke_test_go() {
	local workdir="$1"
	local output

	require_file "$workdir/Makefile"
	require_file "$workdir/cmd/app/main.go"
	require_file "$workdir/test/e2e/smoke_test.go"

	pushd "$workdir" >/dev/null
	go mod init example.com/template-smoke >/dev/null
	go test ./...
	output="$(go run ./cmd/app)"
	popd >/dev/null

	grep -qx 'Go project ready\.' <<<"$output" || fail "Unexpected Go app output: $output"
}

smoke_test_javascript() {
	local workdir="$1"
	local output

	require_file "$workdir/package.json"
	require_file "$workdir/package-lock.json"
	require_file "$workdir/eslint.config.js"
	require_file "$workdir/vitest.config.js"
	[[ ! -e "$workdir/node_modules" ]] || fail "node_modules should not be copied by stack setup"

	mkdir -p "$workdir/src/shared" "$workdir/src/node" "$workdir/test"
	cat <<'EOF' >"$workdir/src/shared/message.js"
export function message() {
  return "template smoke";
}
EOF
	cat <<'EOF' >"$workdir/src/node/index.js"
import { message } from "../shared/message.js";

console.log(message());
EOF
	cat <<'EOF' >"$workdir/test/smoke.test.js"
import { describe, expect, it } from "vitest";
import { message } from "../src/shared/message.js";

describe("message", () => {
  it("returns the smoke string", () => {
    expect(message()).toBe("template smoke");
  });
});
EOF

	pushd "$workdir" >/dev/null
	npm ci --no-audit --no-fund
	npm run lint
	npm run test
	npm run coverage
	output="$(node src/node/index.js)"
	popd >/dev/null

	grep -qx 'template smoke' <<<"$output" || fail "Unexpected JavaScript app output: $output"
}

smoke_test_php() {
	local workdir="$1"
	local output

	require_file "$workdir/composer.json"
	require_file "$workdir/pest.xml"
	require_file "$workdir/src/Application.php"
	require_file "$workdir/tests/Unit/ApplicationTest.php"

	pushd "$workdir" >/dev/null
	XDEBUG_MODE=off composer install --no-interaction --no-progress
	XDEBUG_MODE=off composer validate --strict --no-check-lock
	XDEBUG_MODE=off vendor/bin/pest --configuration=pest.xml --no-coverage
	output="$(XDEBUG_MODE=off php public/index.php)"
	popd >/dev/null

	grep -qx 'Application v0.1.0 is running' <<<"$output" || fail "Unexpected PHP app output: $output"
}

if [[ $# -ne 1 ]]; then
	usage >&2
	exit 1
fi

stack="$1"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

case "$stack" in
	go|javascript|php) ;;
	*)
		usage >&2
		fail "Unsupported stack: $stack"
		;;
esac

setup_stack "$stack" "$workdir"

case "$stack" in
	go)
		smoke_test_go "$workdir"
		;;
	javascript)
		smoke_test_javascript "$workdir"
		;;
	php)
		smoke_test_php "$workdir"
		;;
esac

echo "Smoke test passed for $stack"
