#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <install|deinit|uninstall>" >&2
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

  if [[ -x "$HOME/.local/bin/rtk" ]]; then
    printf '%s\n' "$HOME/.local/bin/rtk"
    return 0
  fi

  return 1
}

report_agents_rtk_references() {
  local agents_file="$1"
  grep -Fq 'RTK.md' "$agents_file"
}

install_with_brew() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "RTK install script only supports macOS." >&2
    return 1
  fi

  if [[ "$(uname -m)" != "arm64" ]]; then
    echo "RTK install script only supports Apple Silicon Macs." >&2
    return 1
  fi

  if ! command -v brew >/dev/null 2>&1; then
    return 1
  fi

  echo "Installing RTK with Homebrew..."
  brew install rtk
}

deinit_codex_integration() {
  local rtk_bin

  if ! rtk_bin="$(resolve_rtk_bin)"; then
    echo "RTK is not installed, so Codex integration cannot be deinitialized through RTK." >&2
    exit 1
  fi

  echo "Using RTK binary: $rtk_bin"
  "$rtk_bin" --version

  echo "Deinitializing RTK for Codex without removing the RTK binary..."
  if ! "$rtk_bin" init -g --codex --uninstall; then
    echo "Failed to deinitialize RTK for Codex." >&2
    exit 1
  fi

  echo "Verified RTK deinit command:"
  echo "  $rtk_bin init -g --codex --show"
  "$rtk_bin" init -g --codex --show || true

  ensure_codex_deinitialized

  if command -v rtk >/dev/null 2>&1; then
    echo "RTK binary remains installed at: $(command -v rtk)"
  fi
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

  if ! report_agents_rtk_references "$agents_file" "$rtk_file"; then
    echo "$agents_file exists, but no RTK reference form was found after RTK init." >&2
    return 1
  fi
}

ensure_codex_deinitialized() {
  local agents_file="$HOME/.codex/AGENTS.md"
  local rtk_file="$HOME/.codex/RTK.md"

  if [[ -f "$rtk_file" ]]; then
    echo "RTK deinit completed, but $rtk_file still exists." >&2
    return 1
  fi

  if [[ -f "$agents_file" ]]; then
    if report_agents_rtk_references "$agents_file" "$rtk_file"; then
      echo "RTK deinit completed, but $agents_file still contains an RTK reference form." >&2
      return 1
    else
      echo "RTK deinit completed and no RTK reference forms remain in $agents_file."
    fi
  fi
}

install_rtk() {
  local rtk_bin

  if ! rtk_bin="$(resolve_rtk_bin)"; then
    if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
      echo "RTK plugin support is limited to Apple Silicon macOS." >&2
      exit 1
    fi

    if ! install_with_brew; then
      echo "RTK is not installed and could not be installed with Homebrew." >&2
      echo "Install it with 'brew install rtk' and try again." >&2
      exit 1
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
    echo "Failed to initialize RTK for Codex." >&2
    exit 1
  fi

  ensure_codex_integration

  echo "Verified RTK init command:"
  echo "  $rtk_bin init -g --codex --show"
  "$rtk_bin" init -g --codex --show || true

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

uninstall_rtk() {
  if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
    echo "RTK plugin support is limited to Apple Silicon macOS." >&2
    exit 1
  fi

  echo "Warning: this removes the RTK CLI from the machine."
  echo "Other agents or tools on this machine may still rely on it."

  if command -v brew >/dev/null 2>&1 && brew list --formula rtk >/dev/null 2>&1; then
    echo "Removing RTK installed with Homebrew..."
    brew uninstall rtk
  else
    echo "RTK was not removed through Homebrew."
  fi

  echo "RTK uninstall does not modify ~/.codex/RTK.md or ~/.codex/AGENTS.md."
  echo "If you also want to remove Codex integration, run the RTK deinit flow first."

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
    deinit)
      deinit_codex_integration
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
