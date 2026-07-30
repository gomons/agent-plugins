#!/bin/sh
set -eu

command -v jq >/dev/null 2>&1 || {
  echo "jq is required to generate marketplace output." >&2
  exit 1
}

TARGET=${1:-all}
CODEX_OUT=${CODEX_OUT:-.codex-marketplace}
CLAUDE_OUT=${CLAUDE_OUT:-.claude-marketplace}
PLUGINS=
REPOSITORY_ROOT=$(pwd -P)
SOURCE_PLUGINS_ROOT="$REPOSITORY_ROOT/plugins"

normalize_absolute_path() {
  awk -v path="$1" '
    BEGIN {
      count = split(path, parts, "/")
      depth = 0
      for (i = 1; i <= count; i++) {
        part = parts[i]
        if (part == "" || part == ".") {
          continue
        }
        if (part == "..") {
          if (depth > 0) {
            depth--
          }
          continue
        }
        stack[++depth] = part
      }

      printf "/"
      for (i = 1; i <= depth; i++) {
        printf "%s%s", (i == 1 ? "" : "/"), stack[i]
      }
      printf "\n"
    }
  '
}

canonical_path() {
  candidate=$1
  case "$candidate" in
    /*) ;;
    *) candidate="$REPOSITORY_ROOT/$candidate" ;;
  esac

  existing=$candidate
  suffix=
  while [ ! -e "$existing" ]; do
    leaf=${existing##*/}
    suffix="/$leaf$suffix"
    parent=${existing%/*}
    [ -n "$parent" ] || parent=/
    [ "$parent" != "$existing" ] || break
    existing=$parent
  done

  if [ -d "$existing" ]; then
    existing=$(CDPATH='' cd "$existing" && pwd -P)
  else
    leaf=${existing##*/}
    parent=${existing%/*}
    [ -n "$parent" ] || parent=/
    existing=$(CDPATH='' cd "$parent" && printf '%s/%s\n' "$(pwd -P)" "$leaf")
  fi

  normalize_absolute_path "$existing$suffix"
}

validate_output_path() {
  label=$1
  output=$2
  canonical_output=$(canonical_path "$output")

  case "$canonical_output" in
    "$REPOSITORY_ROOT" | "$SOURCE_PLUGINS_ROOT" | "$SOURCE_PLUGINS_ROOT"/*)
      echo "Refusing unsafe $label output path: $output overlaps repository sources." >&2
      exit 2
      ;;
  esac
}

validate_plugin_sources() {
  if ! jq -e '
    .plugins as $plugins
    | ($plugins | type == "array" and length > 0)
      and all(
        $plugins[];
        type == "string"
        and length <= 64
        and test("^[a-z0-9]+(-[a-z0-9]+)*$")
      )
      and (($plugins | length) == ($plugins | unique | length))
  ' marketplace/source.json >/dev/null; then
    echo "Plugin names must be unique lowercase hyphen-case values of 64 characters or fewer." >&2
    exit 2
  fi

  PLUGINS=$(jq -r '.plugins[]' marketplace/source.json)
  for plugin in $PLUGINS; do
    if [ ! -f "plugins/$plugin/plugin.source.json" ]; then
      echo "Missing plugin source manifest: plugins/$plugin/plugin.source.json" >&2
      exit 2
    fi
  done
}

case "$TARGET" in
  all | codex | claude) ;;
  *)
    echo "Usage: $0 [all|codex|claude]" >&2
    exit 2
    ;;
esac

validate_plugin_sources

if [ "$TARGET" = all ] || [ "$TARGET" = codex ]; then
  validate_output_path "Codex" "$CODEX_OUT"
fi

if [ "$TARGET" = all ] || [ "$TARGET" = claude ]; then
  validate_output_path "Claude" "$CLAUDE_OUT"
fi

plugin_manifest() {
  plugin=$1
  platform=$2

  jq --arg platform "$platform" '
    def compact_object:
      with_entries(select(.value != null and .value != ""));

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

  cp marketplace/README.codex.md "$out/README.md"

  jq '
    . as $root
    | $root.platforms.codex
      + {
        plugins: (
          $root.plugins
          | map(
              . as $plugin
              |
              {
                name: $plugin,
                source: ($root.pluginDefaults.source + {path: ("./plugins/" + $plugin)}),
                policy: (
                  $root.pluginDefaults.policy
                  * ($root.pluginOverrides[$plugin].policy // {})
                ),
                category: (
                  $root.pluginOverrides[$plugin].category
                  // $root.pluginDefaults.category
                )
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

  cp marketplace/README.claude.md "$out/README.md"

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
