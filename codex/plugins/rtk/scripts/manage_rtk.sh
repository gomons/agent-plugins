#!/usr/bin/env bash

set -euo pipefail

usage() {
  echo "Usage: $0 <install|deinit|uninstall>" >&2
  exit 1
}

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

report_agents_rtk_references() {
  local agents_file="$1"
  local rtk_file="$2"
  local short_ref='@RTK.md'
  local path_ref="@${rtk_file}"
  local found=1

  if grep -Fxq "$short_ref" "$agents_file"; then
    echo "Found RTK AGENTS.md reference form: $short_ref"
    found=0
  else
    echo "RTK AGENTS.md reference form not found: $short_ref"
  fi

  if grep -Fxq "$path_ref" "$agents_file"; then
    echo "Found RTK AGENTS.md reference form: $path_ref"
    found=0
  else
    echo "RTK AGENTS.md reference form not found: $path_ref"
  fi

  if grep -Fq 'RTK.md' "$agents_file"; then
    echo "Found RTK AGENTS.md reference form: RTK.md"
    found=0
  else
    echo "RTK AGENTS.md reference form not found: RTK.md"
  fi

  return "$found"
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
    if ! "$rtk_bin" init --global --codex --uninstall; then
      echo "Failed to deinitialize RTK for Codex." >&2
      exit 1
    fi
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
      echo "RTK deinit completed and no RTK reference forms remain in $agents_file."
    else
      echo "RTK deinit completed, but $agents_file still contains an RTK reference form." >&2
      return 1
    fi
  fi
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
  echo "Warning: this removes the RTK CLI from the machine."
  echo "Other agents or tools on this machine may still rely on it."

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
