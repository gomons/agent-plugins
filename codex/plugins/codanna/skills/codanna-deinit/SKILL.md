---
name: "codanna-deinit"
description: "Remove Codanna project state from the current repository when the workspace should no longer be indexed by Codanna."
---

# Codanna Deinit

Use this skill when the current repository should be deinitialized for Codanna.

## Goals

- Confirm the target repository contains `.codanna/`.
- Remove the repository-local Codanna state.
- Make clear that this does not uninstall the global `codanna` CLI.

## Workflow

1. From the plugin root, run `./scripts/deinit_codanna.sh <repo-root>`.
2. Verify that `<repo-root>/.codanna/` no longer exists.
3. Tell the user that the repository is no longer bootstrapped for the Codanna MCP server.

## Notes

- This skill is destructive because it deletes `.codanna/` from the target repository.
- Use `codanna-uninstall` only when the user wants to remove the machine-wide CLI as well.
- This plugin is Apple Silicon macOS-only.
