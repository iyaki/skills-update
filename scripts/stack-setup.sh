#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
STACK=""
TARGET_DIR=""
FORCE=0
DRY_RUN=0

SUPPORTED_STACKS="javascript go php"

confirm_overwrite() {
  _file="$1"
  printf "Overwrite '%s'? [y/N/a(ll)] " "$_file" >&2
  read -r _answer </dev/tty
  case "$_answer" in
    [yY]) return 0 ;;
    [aA]) FORCE=1; return 0 ;;
    *) return 1 ;;
  esac
}

usage() {
  cat <<'USAGE'
Usage:
  scripts/stack-setup.sh STACK [--target DIR] [--force] [--dry-run]

Arguments:
  STACK          Stack template to set up (supported: javascript, go, php).

Options:
  --target DIR   Target directory. Default: repository root (or cwd).
  --force        Overwrite existing files without prompting.
  --dry-run      Show what would be copied without writing.
  --help         Show this help.
USAGE
}

if [ "$#" -eq 0 ]; then
  echo "Error: missing stack template argument." >&2
  usage >&2
  exit 1
fi

case "$1" in
  --help|-h)
    usage
    exit 0
    ;;
  -*)
    echo "Error: stack template must be passed as the first argument after the script path." >&2
    usage >&2
    exit 1
    ;;
  *)
    STACK="$1"
    shift
    ;;
esac

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target)
      if [ "$#" -lt 2 ]; then
        echo "Missing value for --target" >&2
        exit 1
      fi
      TARGET_DIR="$2"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unrecognized argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$STACK" in
  javascript|go|php) ;;
  *)
    echo "Error: unsupported stack '$STACK'. Supported stacks: $SUPPORTED_STACKS" >&2
    exit 1
    ;;
esac

SOURCE_DIR="$SCRIPT_DIR/../templates/$STACK"

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Template source does not exist: $SOURCE_DIR" >&2
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Target directory does not exist: $TARGET_DIR" >&2
  exit 1
fi

COPIED=0
SKIPPED=0

cd "$SOURCE_DIR"
file_list=$(mktemp)
find . \
  \( -name node_modules -o -name .git -o -name coverage -o -name dist \) -prune \
  -o -type f -print > "$file_list"

while IFS= read -r relpath; do
  clean_relpath=${relpath#./}
  src="$SOURCE_DIR/$clean_relpath"
  dst="$TARGET_DIR/$clean_relpath"
  dstdir=$(dirname "$dst")

  if [ "$DRY_RUN" -eq 1 ]; then
    if [ -f "$dst" ] && [ "$FORCE" -ne 1 ]; then
      echo "SKIP $clean_relpath (already exists)"
    else
      echo "COPY $clean_relpath"
    fi
    continue
  fi

  mkdir -p "$dstdir"

  if [ -f "$dst" ] && [ "$FORCE" -ne 1 ]; then
    if ! confirm_overwrite "$clean_relpath"; then
      echo "SKIP $clean_relpath"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
  fi

  cp "$src" "$dst"
  echo "COPY $clean_relpath"
  COPIED=$((COPIED + 1))
done < "$file_list"

rm -f "$file_list"

if [ "$DRY_RUN" -eq 1 ]; then
  printf "\nDry-run complete.\n"
else
  printf "\nStack '%s' deployed to: %s\n" "$STACK" "$TARGET_DIR"
  echo "Files copied:  $COPIED"
  echo "Files skipped: $SKIPPED"
  case "$STACK" in
    javascript)
      printf "\nRecommended next step: npm install && npm run verify\n"
      ;;
    go)
      printf "\nRecommended next step: make tools && make verify\n"
      ;;
    php)
      printf "\nRecommended next step: composer install && composer verify\n"
      ;;
  esac
fi
