#!/bin/sh
set -eu

command -v jq >/dev/null 2>&1 || {
  echo "jq is required to generate marketplace output." >&2
  exit 1
}

TARGET=${1:-all}
CODEX_OUT=${CODEX_OUT:-.codex-marketplace}
CLAUDE_OUT=${CLAUDE_OUT:-.claude-marketplace}
PLUGINS=$(jq -r '.plugins[]' marketplace/source.json)

case "$TARGET" in
  all|codex|claude) ;;
  *)
    echo "Usage: $0 [all|codex|claude]" >&2
    exit 2
    ;;
esac

plugin_manifest() {
  plugin=$1
  platform=$2

  jq --arg platform "$platform" '
    def compact_object:
      with_entries(select(.value != null));

    def ordered_interface:
      {
        displayName,
        shortDescription,
        longDescription,
        developerName,
        category,
        capabilities,
        websiteURL,
        privacyPolicyURL,
        termsOfServiceURL,
        defaultPrompt,
        brandColor
      }
      | compact_object;

    def ordered_plugin:
      {
        name,
        version,
        description,
        author,
        homepage,
        repository,
        license,
        keywords,
        skills,
        mcpServers,
        interface: (.interface | ordered_interface)
      }
      | compact_object;

    .common * (.platforms[$platform] // {})
    | ordered_plugin
  ' "plugins/$plugin/plugin.source.json"
}

mcp_manifest() {
  plugin=$1
  platform=$2

  jq --arg platform "$platform" '
    .common * (.platforms[$platform] // {})
  ' "plugins/$plugin/mcp.source.json"
}

copy_plugin_files() {
  plugin=$1
  platform=$2
  out=$3
  manifest_dir=$4

  plugin_out="$out/plugins/$plugin"
  rm -rf "$plugin_out"
  mkdir -p "$plugin_out/$manifest_dir"

  plugin_manifest "$plugin" "$platform" > "$plugin_out/$manifest_dir/plugin.json"

  if [ -f "plugins/$plugin/mcp.source.json" ]; then
    mcp_manifest "$plugin" "$platform" > "$plugin_out/.mcp.json"
  fi

  if [ -d "plugins/$plugin/skills" ]; then
    mkdir -p "$plugin_out/skills"
    rsync -a --delete "plugins/$plugin/skills/" "$plugin_out/skills/"
  fi
}

generate_codex_marketplace() {
  out=$1
  mkdir -p "$out/.agents/plugins"
  rm -rf "$out/plugins"

  jq '
    . as $root
    | $root.platforms.codex
      + {
        plugins: (
          $root.plugins
          | map(
              {
                name: .,
                source: ($root.pluginDefaults.source + {path: ("./plugins/" + .)}),
                policy: $root.pluginDefaults.policy,
                category: $root.pluginDefaults.category
              }
            )
        )
      }
  ' marketplace/source.json > "$out/.agents/plugins/marketplace.json"

  for plugin in $PLUGINS; do
    copy_plugin_files "$plugin" codex "$out" .codex-plugin
  done
}

generate_claude_marketplace() {
  out=$1
  mkdir -p "$out/.claude-plugin"
  rm -rf "$out/plugins"

  entries='[]'
  for plugin in $PLUGINS; do
    entry=$(
      jq --arg plugin "$plugin" '
        .common * (.platforms.claude // {})
        | {
            name,
            source: ("./plugins/" + $plugin),
            description,
            version,
            author,
            category: (.interface.category // "Developer Tools")
          }
      ' "plugins/$plugin/plugin.source.json"
    )
    entries=$(printf '%s\n%s\n' "$entries" "$entry" | jq -s '.[0] + [.[1]]')
  done

  jq --argjson plugins "$entries" '
    .platforms.claude
    | {
        "$schema": "https://json.schemastore.org/claude-code-marketplace.json",
        name,
        version,
        description,
        owner,
        plugins: $plugins
      }
  ' marketplace/source.json > "$out/.claude-plugin/marketplace.json"

  for plugin in $PLUGINS; do
    copy_plugin_files "$plugin" claude "$out" .claude-plugin
  done
}

if [ "$TARGET" = all ] || [ "$TARGET" = codex ]; then
  generate_codex_marketplace "$CODEX_OUT"
fi

if [ "$TARGET" = all ] || [ "$TARGET" = claude ]; then
  generate_claude_marketplace "$CLAUDE_OUT"
fi
