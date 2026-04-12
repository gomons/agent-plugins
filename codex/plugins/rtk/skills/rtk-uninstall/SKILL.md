---
name: "rtk-uninstall"
description: "Uninstall Rust Token Killer from the machine after warning that other agents may still depend on it."
---

# RTK Uninstall

Use this skill when the RTK CLI itself should be removed from the current machine.

## Workflow

1. From the plugin root, run:
   `./scripts/manage_rtk.sh uninstall`
2. Warn before running it:
   This removes the RTK CLI binary from the machine, not just Codex integration.
   Other agents or tools on the same machine may still rely on the `rtk` binary.
3. Confirm cleanup:
   `test ! -f "$HOME/.codex/RTK.md"`
   `command -v rtk` should return no result
4. The plugin does not rewrite or clean `AGENTS.md`; RTK owns that file's integration state.

## Notes

- The uninstall path removes the RTK CLI only when it was installed through Homebrew.
- This plugin is Apple Silicon macOS-only and expects the RTK binary in `/opt/homebrew/bin`.
- If the binary came from a manual download or another package manager, the script reports the remaining executable path instead of deleting it blindly.
- The plugin does not edit `AGENTS.md` during uninstall, so any stale `RTK.md` reference must be cleaned up separately if desired.
