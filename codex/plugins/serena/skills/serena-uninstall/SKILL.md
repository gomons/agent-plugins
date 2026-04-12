---
name: "serena-uninstall"
description: "Uninstall the global Serena CLI from this Apple Silicon Mac."
---

# Serena Uninstall

Use this skill when the user wants to remove the machine-wide `serena` CLI.

## Goals

- Uninstall the global Serena CLI.
- Confirm that `serena` no longer resolves in `PATH`.
- Make clear that this removes the CLI, not any unrelated project source code.

## Workflow

1. From the plugin root, run `./scripts/uninstall_serena.sh`.
2. In a fresh shell, verify that `command -v serena` no longer resolves.
3. Tell the user that the Serena MCP plugin will remain unavailable until `serena-install` is run again.

## Notes

- This plugin is Apple Silicon macOS-only.
- The uninstall flow uses `uv tool uninstall serena`.
