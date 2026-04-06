# Codex Plugins

This subtree is a self-contained source of plugins for Codex.

## Structure

- `.agents/plugins/marketplace.json` is the catalog entrypoint.
- `plugins/<name>/` contains one plugin per directory.
- `plugins/<name>/.codex-plugin/plugin.json` is the plugin manifest.
- `plugins/<name>/.mcp.json` contains MCP server definitions when the plugin exposes MCP servers.

## Add a plugin

1. Create `plugins/<name>/`.
2. Add `.codex-plugin/plugin.json`.
3. Add optional companion files such as `.mcp.json`.
4. Register the plugin in `.agents/plugins/marketplace.json`.

## Use this source

Point Codex at this `codex/` directory as the plugin source root.
