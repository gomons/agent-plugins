---
name: "serena-install"
description: "Install or verify the global Serena CLI on this Apple Silicon Mac and confirm which executable the plugin launcher will use."
---

# Serena Install

Use this skill when the Serena CLI may be missing from the machine and the Serena MCP launcher cannot start.

## Goals

- Ensure `serena` is installed on the machine.
- Resolve the binary path that the plugin launcher should use.
- Confirm which executable will be used by the launcher.

## Workflow

1. From the plugin root, run `./scripts/install_serena.sh`.
2. In the same shell, resolve the executable with `command -v serena`.
3. Verify the CLI with `serena --help`.
4. If the current project should be prepared for Serena usage in this Codex session, switch to `serena-init`.

## Notes

- This plugin is Apple Silicon macOS-only.
- The launcher looks for `serena` in `/opt/homebrew/bin`, `$HOME/.local/bin`, and the inherited `PATH`.
- The installer uses Homebrew for `uv` if needed, then installs the Serena CLI globally with `uv tool install --from git+https://github.com/oraios/serena serena`.
