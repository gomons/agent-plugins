---
name: "codanna-install"
description: "Install or verify the Codanna binary on the current machine and confirm which executable the plugin launcher will use."
---

# Codanna Install

Use this skill when the Codanna binary may be missing from the machine and you want to install or verify it.

## Goals

- Ensure `codanna` is installed on the machine.
- Resolve the binary path that the plugin should use, including user-local installs in `~/.local/bin`.
- Confirm which executable will be used by the plugin launcher.

## Workflow

1. From the skill directory, run `./install_codanna.sh`.
2. In the same shell, resolve the executable with `command -v codanna` after running the installer. The plugin launcher checks `/opt/homebrew/bin`, `~/.local/bin`, and the inherited `PATH`.
3. Verify installation with the resolved executable:
   `CODANNA_BIN="$(command -v codanna)"`
   `"$CODANNA_BIN" --version`
4. If the current repository still needs Codanna project bootstrap, switch to the `codanna-init` skill.

## Notes

- This plugin is Apple Silicon macOS-only and installs Codanna through Homebrew by default.
- The launcher resolves `codanna` from `/opt/homebrew/bin`, `~/.local/bin`, and the inherited `PATH`.
- This skill installs the binary only. Project initialization and index creation belong to the `codanna-init` skill.
- The plugin launcher only starts Codanna when the current project already has `.codanna/settings.toml` and a non-empty `.codanna/index/`.
- When that index exists, the launcher refreshes it with `codanna index` before starting the MCP server.
- If the project has never been initialized or indexed, the launcher intentionally does not run `codanna init` for you and exits with an explicit error so agents can understand why Codanna is unavailable.
- If `command -v codanna` still fails in a fresh shell, re-open the shell, update `PATH`, or keep using the resolved absolute path from the installation shell.
