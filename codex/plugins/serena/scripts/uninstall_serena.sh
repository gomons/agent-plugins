#!/bin/sh
set -eu

PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"
export PATH

show_help() {
  cat <<'EOF'
Usage: uninstall_serena.sh

Uninstalls the global Serena CLI from an Apple Silicon Mac.
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
  echo "uninstall_serena.sh only supports macOS." >&2
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "uninstall_serena.sh only supports Apple Silicon Macs." >&2
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required to uninstall Serena on this machine." >&2
  exit 1
fi

uv tool uninstall serena
