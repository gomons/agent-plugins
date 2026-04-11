---
name: "rtk-install"
description: "Install Rust Token Killer and initialize its global Codex integration."
---

# RTK Install

Use this skill when Rust Token Killer should be installed or re-applied on the current machine.

## Workflow

1. From the plugin root, run:
   `./scripts/manage_rtk.sh install`
2. The install flow runs RTK's global Codex init automatically with:
   `rtk init -g --codex`
3. Confirm the result:
   `RTK_BIN="$(command -v rtk)"`
   `"$RTK_BIN" --version`
   `"$RTK_BIN" init -g --codex --show`
   `test -f "$HOME/.codex/RTK.md"`
   `test -f "$HOME/.codex/AGENTS.md"`
   `grep -Fxq '@RTK.md' "$HOME/.codex/AGENTS.md" || grep -Fxq "@$HOME/.codex/RTK.md" "$HOME/.codex/AGENTS.md" || grep -Fq 'RTK.md' "$HOME/.codex/AGENTS.md"`

## Notes

- The official RTK flow integrates with Codex through files in `~/.codex`, not through an MCP server in this plugin.
- The canonical manual init command for current RTK versions is `rtk init -g --codex`. Use `rtk init -g --codex --show` to inspect the resulting global Codex configuration.
- The install path prefers Homebrew on macOS, then the official RTK installer, then `cargo` as a last fallback. On Linux, Homebrew is still supported when available, but the official installer is the more likely path.
- The install path tries multiple known init flag shapes, then validates that RTK created `~/.codex/RTK.md` and reports which RTK reference forms it finds in `~/.codex/AGENTS.md`: `@RTK.md`, `@~/.codex/RTK.md`, or a softer `RTK.md` match. It does not rewrite or normalize `AGENTS.md`.
