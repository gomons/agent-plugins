#!/bin/sh
set -eu

command -v jq >/dev/null 2>&1 || {
  echo "jq is required to generate plugin manifests." >&2
  exit 1
}

PLATFORMS="codex claude"
PLUGINS=$(jq -r '.plugins[]' marketplace/source.json)

generate_marketplace() {
  platform=$1

  jq --arg platform "$platform" '
    . as $root
    | $root.platforms[$platform]
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
  ' marketplace/source.json > "marketplace/$platform.json"
}

generate_plugin_manifest() {
  plugin=$1
  platform=$2
  mkdir -p "plugins/$plugin/$platform"

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
  ' "plugins/$plugin/plugin.source.json" > "plugins/$plugin/$platform/plugin.json"
}

generate_mcp_manifest() {
  plugin=$1
  platform=$2
  source="plugins/$plugin/mcp.source.json"

  [ -f "$source" ] || return 0
  mkdir -p "plugins/$plugin/$platform"

  jq --arg platform "$platform" '
    .common * (.platforms[$platform] // {})
  ' "$source" > "plugins/$plugin/$platform/mcp.json"
}

for platform in $PLATFORMS; do
  generate_marketplace "$platform"

  for plugin in $PLUGINS; do
    generate_plugin_manifest "$plugin" "$platform"
    generate_mcp_manifest "$plugin" "$platform"
  done
done
