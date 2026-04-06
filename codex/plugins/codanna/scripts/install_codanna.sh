#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
LOCAL_BIN_DIR="$PLUGIN_DIR/.local/bin"

refresh_path() {
  PATH="$LOCAL_BIN_DIR:$HOME/.local/bin:$HOME/.cargo/bin:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$PATH"
  export PATH
}

have_codanna() {
  command -v codanna >/dev/null 2>&1
}

show_help() {
  cat <<'EOF'
Usage: install_codanna.sh [--check]

Installs Codanna using official installation paths when it is missing.

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

mkdir -p "$LOCAL_BIN_DIR"

echo "Codanna is not installed. Attempting installation..." >&2

if command -v curl >/dev/null 2>&1; then
  echo "Trying official installer from https://install.codanna.sh" >&2
  if curl -fsSL --proto '=https' --tlsv1.2 https://install.codanna.sh | sh; then
    refresh_path
  fi
fi

if have_codanna; then
  codanna --version
  exit 0
fi

if command -v brew >/dev/null 2>&1; then
  echo "Trying Homebrew installation" >&2
  if brew list codanna >/dev/null 2>&1 || brew install codanna; then
    refresh_path
  fi
fi

if have_codanna; then
  codanna --version
  exit 0
fi

if command -v cargo >/dev/null 2>&1; then
  echo "Trying Cargo installation into plugin-local directory" >&2
  if cargo install codanna --locked --root "$PLUGIN_DIR/.local"; then
    refresh_path
  fi
fi

if have_codanna; then
  codanna --version
  exit 0
fi

if command -v nix >/dev/null 2>&1; then
  echo "Trying Nix profile installation" >&2
  if nix profile install github:bartolli/codanna; then
    refresh_path
  fi
fi

if have_codanna; then
  codanna --version
  exit 0
fi

cat >&2 <<'EOF'
Unable to install Codanna automatically.

Supported automatic paths:
  1. Official installer: curl -fsSL https://install.codanna.sh | sh
  2. Homebrew: brew install codanna
  3. Cargo: cargo install codanna --locked
  4. Nix: nix profile install github:bartolli/codanna

After installation, ensure `codanna` is available in PATH.
EOF
exit 1
