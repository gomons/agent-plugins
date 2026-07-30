#!/bin/sh
set -eu

REPOSITORY_ROOT=$(pwd -P)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/agent-plugins-generate.XXXXXX")

cleanup() {
  rm -rf "$TEST_ROOT"
}

trap cleanup EXIT HUP INT TERM

create_fixture() {
  fixture=$1
  mkdir -p "$fixture"
  cp -R "$REPOSITORY_ROOT/marketplace" "$fixture/marketplace"
  cp -R "$REPOSITORY_ROOT/plugins" "$fixture/plugins"
  cp -R "$REPOSITORY_ROOT/scripts" "$fixture/scripts"
}

assert_rejected() {
  fixture=$1
  target=$2
  output_variable=$3
  output=$4
  expected_label=$5
  log=$6

  if (
    cd "$fixture"
    env "$output_variable=$output" ./scripts/generate.sh "$target"
  ) >"$log" 2>&1; then
    echo "Expected $target output '$output' to be rejected." >&2
    exit 1
  fi

  grep -F "Refusing unsafe $expected_label output path" "$log" >/dev/null
  test -f "$fixture/plugins/rtk/plugin.source.json"
}

assert_source_rejected() {
  fixture=$1
  log=$2
  expected=$3

  if (
    cd "$fixture"
    CODEX_OUT="$fixture/output" ./scripts/generate.sh codex
  ) >"$log" 2>&1; then
    echo "Expected invalid plugin sources to be rejected." >&2
    exit 1
  fi

  grep -F "$expected" "$log" >/dev/null
}

root_fixture="$TEST_ROOT/root"
create_fixture "$root_fixture"
assert_rejected \
  "$root_fixture" \
  codex \
  CODEX_OUT \
  . \
  Codex \
  "$TEST_ROOT/root.log"

nested_fixture="$TEST_ROOT/nested"
create_fixture "$nested_fixture"
assert_rejected \
  "$nested_fixture" \
  claude \
  CLAUDE_OUT \
  plugins/generated \
  Claude \
  "$TEST_ROOT/nested.log"

symlink_fixture="$TEST_ROOT/symlink"
create_fixture "$symlink_fixture"
ln -s . "$symlink_fixture/root-link"
assert_rejected \
  "$symlink_fixture" \
  codex \
  CODEX_OUT \
  root-link \
  Codex \
  "$TEST_ROOT/symlink.log"

name_fixture="$TEST_ROOT/name"
create_fixture "$name_fixture"
mkdir -p "$name_fixture/output/sentinel"
touch "$name_fixture/output/sentinel/keep"
jq '.plugins += ["../sentinel"]' \
  "$name_fixture/marketplace/source.json" >"$TEST_ROOT/name-source.json"
mv "$TEST_ROOT/name-source.json" "$name_fixture/marketplace/source.json"
assert_source_rejected \
  "$name_fixture" \
  "$TEST_ROOT/name.log" \
  "Plugin names must be unique lowercase hyphen-case values"
test -f "$name_fixture/output/sentinel/keep"

duplicate_fixture="$TEST_ROOT/duplicate"
create_fixture "$duplicate_fixture"
jq '.plugins += ["rtk"]' \
  "$duplicate_fixture/marketplace/source.json" >"$TEST_ROOT/duplicate-source.json"
mv "$TEST_ROOT/duplicate-source.json" \
  "$duplicate_fixture/marketplace/source.json"
assert_source_rejected \
  "$duplicate_fixture" \
  "$TEST_ROOT/duplicate.log" \
  "Plugin names must be unique lowercase hyphen-case values"

missing_fixture="$TEST_ROOT/missing"
create_fixture "$missing_fixture"
jq '.plugins += ["missing-plugin"]' \
  "$missing_fixture/marketplace/source.json" >"$TEST_ROOT/missing-source.json"
mv "$TEST_ROOT/missing-source.json" "$missing_fixture/marketplace/source.json"
assert_source_rejected \
  "$missing_fixture" \
  "$TEST_ROOT/missing.log" \
  "Missing plugin source manifest: plugins/missing-plugin/plugin.source.json"

valid_fixture="$TEST_ROOT/valid"
create_fixture "$valid_fixture"
(
  cd "$valid_fixture"
  CODEX_OUT="$TEST_ROOT/codex-output" ./scripts/generate.sh codex
)

test -f "$TEST_ROOT/codex-output/.agents/plugins/marketplace.json"
test -f "$TEST_ROOT/codex-output/plugins/rtk/.codex-plugin/plugin.json"
test -f "$valid_fixture/plugins/rtk/plugin.source.json"
jq -e '
  .plugins[]
  | select(.name == "xquik")
  | .policy.authentication == "ON_USE"
' "$TEST_ROOT/codex-output/.agents/plugins/marketplace.json" >/dev/null

echo "Generator path safety tests passed."
