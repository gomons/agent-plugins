---
name: "rtk"
description: "Install, reinstall, or uninstall Rust Token Killer and its Codex integration by selecting a mode."
---

# RTK

Use this skill when Rust Token Killer should be installed, re-applied, or removed on the current machine.

## Modes

- `install`: install RTK if needed, resolve the executable path, and activate RTK's global Codex integration.
- `uninstall`: remove RTK when it was installed through a supported package manager and clean up Codex integration files.

## Workflow

1. Decide the mode explicitly before running anything: `install` or `uninstall`.
2. From the plugin root, run:
   `./scripts/manage_rtk.sh install`
   or
   `./scripts/manage_rtk.sh uninstall`
3. For `install`, confirm the result:
   `RTK_BIN="$(command -v rtk)"`
   `"$RTK_BIN" --version`
   `test -f "$HOME/.codex/RTK.md"`
   `test -f "$HOME/.codex/AGENTS.md"`
4. For `uninstall`, confirm cleanup:
   `test ! -f "$HOME/.codex/RTK.md"`
   `grep -n "gomons-codex-plugins:rtk:start\\|gomons-codex-plugins:rtk:end" "$HOME/.codex/AGENTS.md"` should return no matches when the file still exists.

## Notes

- The official RTK flow integrates with Codex through files in `~/.codex`, not through an MCP server in this plugin.
- The install path prefers Homebrew on macOS, then the official RTK installer, then `cargo` as a last fallback. On Linux, Homebrew is still supported when available, but the official installer is the more likely path.
- The install path tries multiple known init flag shapes and then normalizes `~/.codex/AGENTS.md` to a small managed block owned by `gomons-codex-plugins` instead of relying on arbitrary upstream edits.
- The uninstall path only removes RTK automatically when it was installed through `brew` or `cargo`. If the binary came from a manual download or another package manager, the script reports the remaining executable path instead of deleting it blindly.
