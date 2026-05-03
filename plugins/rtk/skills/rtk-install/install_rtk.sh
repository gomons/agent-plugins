#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 --target codex|claude" >&2
  exit 1
}

resolve_rtk_bin() {
  if command -v rtk >/dev/null 2>&1; then
    command -v rtk
    return 0
  fi

  if [[ -x "/opt/homebrew/bin/rtk" ]]; then
    printf '%s\n' "/opt/homebrew/bin/rtk"
    return 0
  fi

  if [[ -x "/usr/local/bin/rtk" ]]; then
    printf '%s\n' "/usr/local/bin/rtk"
    return 0
  fi

  if [[ -x "$HOME/.local/bin/rtk" ]]; then
    printf '%s\n' "$HOME/.local/bin/rtk"
    return 0
  fi

  return 1
}

install_with_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is not available; skipping Homebrew install." >&2
    return 1
  fi

  echo "Installing RTK with Homebrew..."
  if ! brew install rtk; then
    echo "Homebrew failed to install RTK." >&2
    return 1
  fi
}

install_rtk() {
  local method
  local install_func
  local methods=(
    brew
  )

  if resolve_rtk_bin >/dev/null; then
    return 0
  fi

  for method in "${methods[@]}"; do
    install_func="install_with_${method}"

    if ! declare -F "$install_func" >/dev/null; then
      echo "Unknown RTK install method: $method" >&2
      continue
    fi

    "$install_func" || continue

    if resolve_rtk_bin >/dev/null; then
      return 0
    fi
  done

  echo "RTK is not installed and no install method succeeded." >&2
  return 1
}

ensure_codex_integration() {
  local agents_file="$HOME/.codex/AGENTS.md"
  local rtk_file="$HOME/.codex/RTK.md"

  if [[ ! -f "$rtk_file" ]]; then
    echo "RTK init completed, but $rtk_file was not created." >&2
    return 1
  fi

  if [[ ! -f "$agents_file" ]]; then
    echo "RTK init completed, but $agents_file was not created." >&2
    return 1
  fi

  if ! grep -Fq 'RTK.md' "$agents_file"; then
    echo "$agents_file exists, but no RTK reference was found after RTK init." >&2
    return 1
  fi
}

ensure_claude_integration() {
  local rtk_file="$HOME/.claude/RTK.md"

  if [[ ! -f "$rtk_file" ]]; then
    echo "RTK init completed, but $rtk_file was not created." >&2
    return 1
  fi
}

initialize_codex() {
  local rtk_bin="$1"

  echo "Activating RTK for Codex..."
  if ! "$rtk_bin" init -g --codex; then
    echo "Failed to initialize RTK for Codex." >&2
    return 1
  fi

  ensure_codex_integration
  echo "Verified RTK init command:"
  echo "  $rtk_bin init -g --codex --show"
  "$rtk_bin" init -g --codex --show || true
  echo "RTK Codex integration status:"
  [[ -f "$HOME/.codex/RTK.md" ]]    && echo "  present: $HOME/.codex/RTK.md"    || echo "  missing: $HOME/.codex/RTK.md"
  [[ -f "$HOME/.codex/AGENTS.md" ]] && echo "  present: $HOME/.codex/AGENTS.md" || echo "  missing: $HOME/.codex/AGENTS.md"
}

initialize_claude() {
  local rtk_bin="$1"

  echo "Activating RTK for Claude Code..."
  if ! "$rtk_bin" init -g; then
    echo "Failed to initialize RTK for Claude Code." >&2
    return 1
  fi

  ensure_claude_integration
  echo "RTK Claude Code integration status:"
  [[ -f "$HOME/.claude/RTK.md" ]] && echo "  present: $HOME/.claude/RTK.md" || echo "  missing: $HOME/.claude/RTK.md"
}

initialize_rtk() {
  local target="$1"
  local rtk_bin

  if ! rtk_bin="$(resolve_rtk_bin)"; then
    echo "RTK installation ran, but the binary still could not be resolved in known locations." >&2
    return 1
  fi

  echo "Using RTK binary: $rtk_bin"
  "$rtk_bin" --version

  case "$target" in
    codex) initialize_codex "$rtk_bin" ;;
    claude) initialize_claude "$rtk_bin" ;;
  esac
}

main() {
  local target=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target)
        [[ $# -ge 2 ]] || usage
        target="$2"
        shift 2
        ;;
      *)
        usage
        ;;
    esac
  done

  case "$target" in
    codex|claude) ;;
    *) usage ;;
  esac

  if ! install_rtk; then
    exit 1
  fi

  initialize_rtk "$target"
}

main "$@"
