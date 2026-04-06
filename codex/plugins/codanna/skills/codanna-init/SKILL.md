---
name: "codanna-init"
description: "Initialize the current repository for Codanna, build the first index, and verify that the MCP server can start."
---

# Codanna Init

Use this skill when the current repository should be prepared for Codanna so the MCP server can start successfully.

## Goals

- Confirm `codanna` is installed and available.
- Initialize the current repository for Codanna.
- Build the first project index.
- Verify that the workspace is ready for `codanna serve --watch`.

## Workflow

1. If `codanna` is missing, run `./scripts/install_codanna.sh` from the plugin root first.
2. Verify installation with `codanna --version`.
3. In the target repository, run `codanna init` if `.codanna/settings.toml` does not exist yet.
4. Build the initial index with `codanna index .`.
5. Confirm readiness:
   `test -f .codanna/settings.toml`
   `test -d .codanna/index`
6. Optionally run `codanna mcp-test` to confirm the MCP tool surface is available.

## Notes

- This skill is for project bootstrap, not binary installation alone.
- The Codanna launcher in this plugin will refuse to start when `.codanna/settings.toml` or a non-empty `.codanna/index/` is missing.
- After this skill completes, the plugin launcher should be able to refresh the index and start MCP normally.
