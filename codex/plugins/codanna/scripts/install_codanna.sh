#!/bin/sh
set -eu

refresh_path() {
  PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"
  export PATH
}

have_codanna() {
  command -v codanna >/dev/null 2>&1
}

show_help() {
  cat <<'EOF'
Usage: install_codanna.sh [--check]

Ensures the global `codanna` binary is available on Apple Silicon macOS.

Options:
  --check    Exit 0 if codanna is already available in PATH, 1 otherwise.
  --help     Show this message.
EOF
}

refresh_path

case "${1:-}" in
  --help|-h)
    show_help
    exit 0
    ;;
  --check)
    if have_codanna; then
      exit 0
    fi
    exit 1
    ;;
  "")
    ;;
  *)
    echo "Unsupported argument: $1" >&2
    show_help >&2
    exit 2
    ;;
esac

if have_codanna; then
  codanna --version
  exit 0
fi

if [ "$(uname -s)" != "Darwin" ]; then
  echo "install_codanna.sh only supports macOS." >&2
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "install_codanna.sh only supports Apple Silicon Macs." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required to install Codanna on this machine." >&2
  exit 1
fi

echo "Codanna is not installed. Installing with Homebrew..." >&2

if brew list codanna >/dev/null 2>&1 || brew install codanna; then
  refresh_path
fi

if have_codanna; then
  codanna --version
  exit 0
fi

echo "Homebrew installation completed, but `codanna` is still not available in /opt/homebrew/bin, ~/.local/bin, or PATH." >&2
exit 1
