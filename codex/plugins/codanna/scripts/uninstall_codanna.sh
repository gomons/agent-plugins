#!/bin/sh
set -eu

PATH="/opt/homebrew/bin:$PATH"
export PATH

show_help() {
  cat <<'EOF'
Usage: uninstall_codanna.sh

Uninstalls the global Homebrew codanna CLI from an Apple Silicon Mac.
EOF
}

case "${1:-}" in
  --help|-h)
    show_help
    exit 0
    ;;
  "")
    ;;
  *)
    echo "Unsupported argument: $1" >&2
    show_help >&2
    exit 2
    ;;
esac

if [ "$(uname -s)" != "Darwin" ]; then
  echo "uninstall_codanna.sh only supports macOS." >&2
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "uninstall_codanna.sh only supports Apple Silicon Macs." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required to uninstall Codanna on this machine." >&2
  exit 1
fi

if ! brew list codanna >/dev/null 2>&1; then
  echo "Codanna is not installed via Homebrew." >&2
  exit 0
fi

brew uninstall codanna
