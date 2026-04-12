#!/bin/sh
set -eu

PROJECT_DIR=$(pwd)
PROJECT_CODANNA_DIR="$PROJECT_DIR/.codanna"
PROJECT_SETTINGS="$PROJECT_CODANNA_DIR/settings.toml"
PROJECT_INDEX_DIR="$PROJECT_CODANNA_DIR/index"

PATH="/opt/homebrew/bin:$PATH"
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

if [ "$(uname -s)" != "Darwin" ]; then
  echo "launch_codanna.sh only supports macOS." >&2
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "launch_codanna.sh only supports Apple Silicon Macs." >&2
  exit 1
fi

if ! command -v codanna >/dev/null 2>&1; then
  echo "Codanna is not installed. Install it with 'brew install codanna'." >&2
  exit 1
fi

echo "Codanna launcher: refreshing existing index in $PROJECT_DIR" >&2
codanna index >/dev/null

exec codanna "$@"
