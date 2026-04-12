---
name: "codanna-uninstall"
description: "Uninstall the global Codanna CLI from this Apple Silicon Mac."
---

# Codanna Uninstall

Use this skill when the user wants to remove the machine-wide `codanna` CLI.

## Goals

- Uninstall the global `codanna` binary.
- Confirm that `codanna` no longer resolves in `PATH`.
- Distinguish machine-wide uninstall from repository-local deinitialization.

## Workflow

1. From the plugin root, run `./scripts/uninstall_codanna.sh`.
2. In a fresh shell, verify that `command -v codanna` no longer resolves.
3. If the current repository should also stop carrying Codanna metadata, switch to `codanna-deinit`.

## Notes

- This removes the global CLI but does not delete `.codanna/` directories from repositories.
- This plugin is Apple Silicon macOS-only and uses Homebrew for install and uninstall.
