#!/bin/sh
set -eu

refresh_path() {
  PATH="/opt/homebrew/bin:$HOME/.local/bin:$PATH"
  export PATH
}

have_serena() {
  command -v serena >/dev/null 2>&1
}

show_help() {
  cat <<'EOF'
Usage: install_serena.sh [--check]

Ensures the global Serena CLI is available on Apple Silicon macOS.
The preferred install path uses the official Serena GitHub repository through uv.

Options:
  --check    Exit 0 if serena is already available in PATH, 1 otherwise.
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
    if have_serena; then
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

if have_serena; then
  serena --help >/dev/null 2>&1 || true
  echo "$(command -v serena)"
  exit 0
fi

if [ "$(uname -s)" != "Darwin" ]; then
  echo "install_serena.sh only supports macOS." >&2
  exit 1
fi

if [ "$(uname -m)" != "arm64" ]; then
  echo "install_serena.sh only supports Apple Silicon Macs." >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required to install Serena on this machine." >&2
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is not installed. Installing uv with Homebrew..." >&2
  brew install uv
  refresh_path
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is still not available after Homebrew installation." >&2
  exit 1
fi

echo "Serena is not installed. Installing the global CLI with uv..." >&2
uv tool install --from git+https://github.com/oraios/serena serena
refresh_path

if have_serena; then
  echo "$(command -v serena)"
  exit 0
fi

echo "Serena installation completed, but 'serena' is still not available in PATH." >&2
exit 1
