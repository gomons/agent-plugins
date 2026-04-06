#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
LOCAL_BIN_DIR="$PLUGIN_DIR/.local/bin"
INSTALLER="$SCRIPT_DIR/install_codanna.sh"
PROJECT_DIR=$(pwd)
PROJECT_CODANNA_DIR="$PROJECT_DIR/.codanna"
PROJECT_SETTINGS="$PROJECT_CODANNA_DIR/settings.toml"
PROJECT_INDEX_DIR="$PROJECT_CODANNA_DIR/index"

PATH="$LOCAL_BIN_DIR:$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
export PATH

has_existing_index() {
  [ -f "$PROJECT_SETTINGS" ] || return 1
  [ -d "$PROJECT_INDEX_DIR" ] || return 1
  find "$PROJECT_INDEX_DIR" -mindepth 1 -print -quit 2>/dev/null | grep -q .
}

if ! has_existing_index; then
  echo "Codanna is not initialized for this project: no existing .codanna index was found in $PROJECT_DIR. Run 'codanna init' and 'codanna index .' first." >&2
  exit 1
fi

if ! command -v codanna >/dev/null 2>&1; then
  "$INSTALLER"
  PATH="$LOCAL_BIN_DIR:$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
  export PATH
fi

echo "Codanna launcher: refreshing existing index in $PROJECT_DIR" >&2
codanna index >/dev/null

exec codanna "$@"
