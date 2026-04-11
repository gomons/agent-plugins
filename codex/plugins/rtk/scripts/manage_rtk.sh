#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <install|uninstall>" >&2
  exit 1
}

RTK_BLOCK_START='<!-- gomons-codex-plugins:rtk:start -->'
RTK_BLOCK_REF='@RTK.md'
RTK_BLOCK_END='<!-- gomons-codex-plugins:rtk:end -->'

resolve_rtk_bin() {
  local candidate

  if command -v rtk >/dev/null 2>&1; then
    command -v rtk
    return 0
  fi

  for candidate in \
    "$HOME/.local/bin/rtk" \
    "$HOME/.cargo/bin/rtk" \
    "/opt/homebrew/bin/rtk" \
    "/usr/local/bin/rtk" \
    "/home/linuxbrew/.linuxbrew/bin/rtk"
  do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

install_with_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    return 1
  fi

  echo "Installing RTK with Homebrew..."
  brew install rtk
}

install_with_official_script() {
  if ! command -v curl >/dev/null 2>&1; then
    return 1
  fi

  echo "Installing RTK with the official installer..."
  curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh
}

install_with_cargo() {
  if ! command -v cargo >/dev/null 2>&1; then
    return 1
  fi

  echo "Installing RTK with Cargo..."
  cargo install --git https://github.com/rtk-ai/rtk
}

ensure_codex_integration() {
  local agents_file="$HOME/.codex/AGENTS.md"
  local rtk_file="$HOME/.codex/RTK.md"
  local block_file

  if [[ ! -f "$rtk_file" ]]; then
    echo "RTK init completed, but $rtk_file was not created." >&2
    return 1
  fi

  if [[ ! -f "$agents_file" ]]; then
    echo "RTK init completed, but $agents_file was not created." >&2
    return 1
  fi

  block_file="$(mktemp)"
  cat > "$block_file" <<EOF
$RTK_BLOCK_START
$RTK_BLOCK_REF
$RTK_BLOCK_END
EOF

  if ! grep -Fqx "$RTK_BLOCK_START" "$agents_file" || \
     ! grep -Fqx "$RTK_BLOCK_REF" "$agents_file" || \
     ! grep -Fqx "$RTK_BLOCK_END" "$agents_file"; then
    rm -f "$block_file"
    echo "$agents_file exists, but the managed RTK block is incomplete." >&2
    return 1
  fi

  if ! diff -u <(grep -A2 -F "$RTK_BLOCK_START" "$agents_file" | head -n 3) "$block_file" >/dev/null 2>&1; then
    rm -f "$block_file"
    echo "$agents_file exists, but the managed RTK block does not match the expected content." >&2
    return 1
  fi

  rm -f "$block_file"
}

rewrite_agents_with_managed_block() {
  local agents_file="$HOME/.codex/AGENTS.md"
  local tmp_file
  local clean_file

  mkdir -p "$(dirname "$agents_file")"
  [[ -f "$agents_file" ]] || : > "$agents_file"

  tmp_file="$(mktemp)"
  awk -v start="$RTK_BLOCK_START" -v end="$RTK_BLOCK_END" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    skip != 1 { print }
  ' "$agents_file" > "$tmp_file"

  clean_file="$(mktemp)"
  awk '
    { lines[NR] = $0 }
    END {
      last = NR
      while (last > 0 && lines[last] ~ /^[[:space:]]*$/) {
        last--
      }
      for (i = 1; i <= last; i++) {
        print lines[i]
      }
    }
  ' "$tmp_file" > "$clean_file"

  {
    cat "$clean_file"
    if [[ -s "$clean_file" ]]; then
      printf '\n'
    fi
    printf '%s\n' "$RTK_BLOCK_START"
    printf '%s\n' "$RTK_BLOCK_REF"
    printf '%s\n' "$RTK_BLOCK_END"
  } > "$agents_file"

  rm -f "$tmp_file"
  rm -f "$clean_file"
}

install_rtk() {
  local rtk_bin

  if ! rtk_bin="$(resolve_rtk_bin)"; then
    if ! install_with_brew; then
      if ! install_with_official_script; then
        if ! install_with_cargo; then
          echo "RTK is not installed and no supported installer is available." >&2
          echo "Tried: Homebrew, official RTK installer via curl, Cargo." >&2
          exit 1
        fi
      fi
    fi

    if ! rtk_bin="$(resolve_rtk_bin)"; then
      echo "RTK installation ran, but the binary still could not be resolved in known locations." >&2
      exit 1
    fi
  fi

  echo "Using RTK binary: $rtk_bin"
  "$rtk_bin" --version

  echo "Activating RTK for Codex..."
  if ! "$rtk_bin" init -g --codex; then
    if ! "$rtk_bin" init --global --codex; then
      if ! "$rtk_bin" init --global; then
        echo "Failed to initialize RTK for Codex." >&2
        exit 1
      fi
    fi
  fi

  rewrite_agents_with_managed_block
  ensure_codex_integration

  echo "RTK Codex integration status:"
  if [[ -f "$HOME/.codex/RTK.md" ]]; then
    echo "  present: $HOME/.codex/RTK.md"
  else
    echo "  missing: $HOME/.codex/RTK.md"
  fi

  if [[ -f "$HOME/.codex/AGENTS.md" ]]; then
    echo "  present: $HOME/.codex/AGENTS.md"
  else
    echo "  missing: $HOME/.codex/AGENTS.md"
  fi
}

remove_rtk_reference_from_agents() {
  local agents_file="$HOME/.codex/AGENTS.md"
  local tmp_file

  [[ -f "$agents_file" ]] || return 0

  tmp_file="$(mktemp)"
  awk -v start="$RTK_BLOCK_START" -v end="$RTK_BLOCK_END" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    skip != 1 { print }
  ' "$agents_file" > "$tmp_file"

  if cmp -s "$tmp_file" "$agents_file"; then
    rm -f "$tmp_file"
    return 0
  fi

  mv "$tmp_file" "$agents_file"
}

uninstall_rtk() {
  if command -v brew >/dev/null 2>&1 && brew list --formula rtk >/dev/null 2>&1; then
    echo "Removing RTK installed with Homebrew..."
    brew uninstall rtk
  elif command -v cargo >/dev/null 2>&1 && cargo uninstall rtk; then
    echo "Removed RTK installed with Cargo."
  else
    echo "RTK was not removed through brew or cargo."
  fi

  if [[ -f "$HOME/.codex/RTK.md" ]]; then
    rm -f "$HOME/.codex/RTK.md"
    echo "Removed $HOME/.codex/RTK.md"
  fi

  remove_rtk_reference_from_agents

  if command -v rtk >/dev/null 2>&1; then
    echo "RTK binary still resolves at: $(command -v rtk)"
    echo "If this came from a manual download or another package manager, remove it manually."
  else
    echo "RTK binary no longer resolves in PATH."
  fi
}

main() {
  [[ $# -eq 1 ]] || usage

  case "$1" in
    install)
      install_rtk
      ;;
    uninstall)
      uninstall_rtk
      ;;
    *)
      usage
      ;;
  esac
}

main "$@"
