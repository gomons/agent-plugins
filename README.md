# Agent Plugins

Local plugin marketplace for Codex and Claude Code.

The repository keeps generated manifests in git so plugins can be consumed directly. Maintainers edit source manifests, then regenerate the platform files with `jq`.

## Plugins

- `rtk`: installs Rust Token Killer.
- `codanna`: exposes Codanna MCP.
- `serena`: exposes Serena MCP.
- `git-tools`: local Git workflow skills.

## Requirements

- POSIX shell
- `make`
- `jq`
- `rsync`
- `bash`

## Layout

- `marketplace/source.json`: source for platform marketplace manifests.
- `marketplace/{codex,claude}.json`: generated marketplace manifests.
- `plugins/<plugin>/plugin.source.json`: source for platform plugin manifests.
- `plugins/<plugin>/mcp.source.json`: source for platform MCP config, when needed.
- `plugins/<plugin>/{codex,claude}/`: generated platform files.
- `plugins/<plugin>/skills/`: shipped skills.
- `.codex-marketplace/`, `.claude-marketplace/`: local build outputs.

## Commands

| Command | Purpose |
| --- | --- |
| `make generate` | Regenerate JSON manifests. |
| `make validate` | Check JSON, shell syntax, and generator idempotence. |
| `make codex` | Build `.codex-marketplace/`. |
| `make claude` | Build `.claude-marketplace/`. |
| `make all` | Run generate, validate, and both builds. |
| `make clean` | Remove build outputs. |

Use `make all` for the normal full check. Use `make clean && make all` when you want fresh output directories.

## Editing

Edit source files only:

- `marketplace/source.json`
- `plugins/<plugin>/plugin.source.json`
- `plugins/<plugin>/mcp.source.json`
- `plugins/<plugin>/skills/**`

Do not hand-edit generated files:

- `marketplace/{codex,claude}.json`
- `plugins/<plugin>/{codex,claude}/plugin.json`
- `plugins/<plugin>/{codex,claude}/mcp.json`

After changes:

```sh
make generate
make validate
git diff --check
```

## Source Format

`plugin.source.json` and `mcp.source.json` use:

- `common`: shared fields.
- `platforms.codex`: Codex overrides.
- `platforms.claude`: Claude Code overrides.

`scripts/generate.sh` handles paths and loops; `jq` handles JSON merging and formatting.

## Notes

- Build outputs are ignored by git.
- Builds use `rsync --delete`, so stale output files are removed.
- Generated manifests are tracked intentionally for direct consumption.
