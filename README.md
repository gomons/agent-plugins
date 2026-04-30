# Agent Plugins Source

Source repository for Codex and Claude Code plugin marketplaces.

This repo stores shared plugin sources. Generated marketplace repositories are written to output directories and are not tracked here.

- [gomons/codex-marketplace](https://github.com/gomons/codex-marketplace)
- [gomons/claude-marketplace](https://github.com/gomons/claude-marketplace)

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

## Source Layout

- `marketplace/source.json`: shared marketplace metadata and plugin list.
- `plugins/<plugin>/plugin.source.json`: shared plugin manifest source.
- `plugins/<plugin>/mcp.source.json`: MCP config source, when needed.
- `plugins/<plugin>/skills/`: shipped skills.
- `scripts/generate.sh`: marketplace generator.

Generated files are ignored in this repository.

## Output Layout

Default outputs:

- `.codex-marketplace/`
- `.claude-marketplace/`

Codex output:

- `.agents/plugins/marketplace.json`
- `plugins/<plugin>/.codex-plugin/plugin.json`
- `plugins/<plugin>/.mcp.json`
- `plugins/<plugin>/skills/**`

Claude Code output:

- `.claude-plugin/marketplace.json`
- `plugins/<plugin>/.claude-plugin/plugin.json`
- `plugins/<plugin>/.mcp.json`
- `plugins/<plugin>/skills/**`

## Commands

| Command | Purpose |
| --- | --- |
| `make codex` | Validate sources and generate Codex output. |
| `make claude` | Validate sources and generate Claude Code output. |
| `make all` | Run both `codex` and `claude`. |
| `make clean` | Remove local default outputs only. |

Generate into external marketplace repositories:

```sh
make codex CODEX_OUT=../codex-marketplace
make claude CLAUDE_OUT=../claude-marketplace
make all CODEX_OUT=../codex-marketplace CLAUDE_OUT=../claude-marketplace
```

`make all` does not delete output repository roots. The generator refreshes `plugins/` inside each output and rewrites the marketplace manifest, preserving files such as `.git`.

## Editing

Edit source files only:

- `marketplace/source.json`
- `plugins/<plugin>/plugin.source.json`
- `plugins/<plugin>/mcp.source.json`
- `plugins/<plugin>/skills/**`

Then run:

```sh
make all
```

Commit source changes here. Commit generated output in the separate Codex and Claude Code marketplace repositories.
