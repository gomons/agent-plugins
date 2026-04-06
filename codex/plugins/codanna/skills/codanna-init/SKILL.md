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
2. In the same shell, resolve the executable with `command -v codanna`. The installer script extends `PATH` for that shell to include plugin-local and user-local install locations such as `~/.local/bin`.
3. Verify installation with the resolved executable:
   `CODANNA_BIN="$(command -v codanna)"`
   `"$CODANNA_BIN" --version`
4. In the target repository, run `"$CODANNA_BIN" init` if `.codanna/settings.toml` does not exist yet.
5. Build the initial index with `"$CODANNA_BIN" index .`.
6. Confirm readiness:
   `test -f .codanna/settings.toml`
   `test -d .codanna/index`
7. Optionally run `"$CODANNA_BIN" mcp-test` to confirm the MCP tool surface is available.

## Notes

- This skill is for project bootstrap, not binary installation alone.
- Do not assume the user's shell already resolves `codanna`; prefer the resolved `CODANNA_BIN` path from the installation shell.
- The Codanna launcher in this plugin will refuse to start when `.codanna/settings.toml` or a non-empty `.codanna/index/` is missing.
- After this skill completes, the plugin launcher should be able to refresh the index and start MCP normally.
