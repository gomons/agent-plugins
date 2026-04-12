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
   `command -v rtk` should return no result
4. Tell the user that this flow does not modify `~/.codex/RTK.md` or `~/.codex/AGENTS.md`.
5. If Codex integration should also be removed, switch to `rtk-deinit` before uninstall.

## Notes

- The uninstall path removes the RTK CLI only when it was installed through Homebrew.
- This plugin is Apple Silicon macOS-only and resolves the RTK binary from `/opt/homebrew/bin`, `~/.local/bin`, or the inherited `PATH`.
- If the binary came from a manual download or another package manager, the script reports the remaining executable path instead of deleting it blindly.
- The plugin does not edit `~/.codex/RTK.md` or `~/.codex/AGENTS.md` during uninstall. Use `rtk-deinit` if you want RTK itself to remove its Codex integration first.
