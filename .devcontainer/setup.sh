#!/bin/sh

case "$0" in
	/*) SCRIPT_PATH="$0" ;;
	*) SCRIPT_PATH="$PWD/$0" ;;
esac
SCRIPTPATH="$(CDPATH= cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd -P)"

mkdir -p ~/.local/share/opencode
mkdir -p ~/.local/state/opencode
mkdir -p ~/.config/gh/

ENVFILE_PATH="$SCRIPTPATH/../.env"
if [ ! -f "$ENVFILE_PATH" ]
then
	touch "$ENVFILE_PATH"
fi
