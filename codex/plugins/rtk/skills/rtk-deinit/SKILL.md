---
name: "rtk-deinit"
description: "Remove RTK's global Codex integration while keeping the RTK CLI installed."
---

# RTK Deinit

Use this skill when RTK should stay installed on the machine, but its Codex integration should be removed.

## Workflow

1. From the plugin root, run:
   `./scripts/manage_rtk.sh deinit`
2. The deinit flow runs RTK's Codex deinitialization command:
   `rtk init -g --codex --uninstall`
3. Confirm the result:
   `RTK_BIN="$(command -v rtk)"`
   `"$RTK_BIN" --version`
   `"$RTK_BIN" init -g --codex --show`
   `test ! -f "$HOME/.codex/RTK.md"`
   `test ! -f "$HOME/.codex/AGENTS.md" || ! grep -q "@RTK.md" "$HOME/.codex/AGENTS.md"`
4. The RTK CLI should still be installed after deinit.

## Notes

- This mode is for removing only Codex integration, not the RTK binary itself.
- RTK owns the integration state in `~/.codex`, so the plugin does not rewrite `AGENTS.md`.
- The plugin validates deinit by checking that `~/.codex/RTK.md` is gone and that `~/.codex/AGENTS.md` no longer references `@RTK.md`.
