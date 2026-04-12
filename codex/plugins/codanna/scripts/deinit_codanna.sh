#!/bin/sh
set -eu

show_help() {
  cat <<'EOF'
Usage: deinit_codanna.sh [PROJECT_DIR]

Removes Codanna project state from the target repository by deleting .codanna/.

Arguments:
  PROJECT_DIR  Repository root to deinitialize. Defaults to the current directory.
EOF
}

case "${1:-}" in
  --help|-h)
    show_help
    exit 0
    ;;
esac

PROJECT_DIR="${1:-$(pwd)}"
CODANNA_DIR="$PROJECT_DIR/.codanna"

if [ ! -d "$CODANNA_DIR" ]; then
  echo "No .codanna directory found in $PROJECT_DIR." >&2
  exit 1
fi

rm -rf "$CODANNA_DIR"
echo "Removed $CODANNA_DIR"
