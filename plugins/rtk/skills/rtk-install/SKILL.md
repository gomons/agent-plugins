---
name: "rtk-install"
description: "Install Rust Token Killer and initialize its global agent integration for the target platform."
---

# RTK Install

Use this skill when Rust Token Killer should be installed or re-applied on the current machine.

## Workflow

1. From the skill directory, run:
   `./install_rtk.sh --target codex`   (when installing for Codex)
   `./install_rtk.sh --target claude`  (when installing for Claude Code)
2. The script ensures the RTK binary is available, then runs RTK's global init:
   - Codex: `rtk init -g --codex`
   - Claude Code: `rtk init -g`
3. Confirm the result:
   `RTK_BIN="$(command -v rtk)"`
   `"$RTK_BIN" --version`
   Codex: `test -f "$HOME/.codex/RTK.md"` and `grep -Fq 'RTK.md' "$HOME/.codex/AGENTS.md"`
   Claude Code: `test -f "$HOME/.claude/RTK.md"`

## Notes

- RTK integrates with each platform through files in the agent home directory, not through an MCP server.
- Codex integration: `~/.codex/RTK.md` and `~/.codex/AGENTS.md`.
- Claude Code integration: `~/.claude/RTK.md`.
- The installer checks for available install tools instead of enforcing a specific OS or CPU.
- RTK is installed through Homebrew when it is not already available.
- Known binary locations include Homebrew prefixes and `~/.local/bin`.
