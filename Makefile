CODEX_OUT  := .codex-marketplace
CLAUDE_OUT := .claude-marketplace
JSON_FILES := $(shell find marketplace plugins -name '*.json' -type f)
SH_FILES   := scripts/generate.sh plugins/codanna/skills/codanna-install/install_codanna.sh plugins/serena/skills/serena-install/install_serena.sh
BASH_FILES := plugins/rtk/skills/rtk-install/install_rtk.sh

.PHONY: all generate validate codex claude clean

all: generate validate

generate: codex claude

validate:
	@command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }
	@for f in $(JSON_FILES); do jq empty "$$f"; done
	@for f in $(SH_FILES); do sh -n "$$f"; done
	@for f in $(BASH_FILES); do bash -n "$$f"; done
	@tmp=$$(mktemp -d); \
	CODEX_OUT="$$tmp/codex" CLAUDE_OUT="$$tmp/claude" ./scripts/generate.sh all; \
	for f in $$(find "$$tmp" -name '*.json' -type f); do jq empty "$$f"; done; \
	jq -e '.name and .plugins and (.plugins | length > 0)' "$$tmp/codex/.agents/plugins/marketplace.json" >/dev/null; \
	jq -e '.["$$schema"] and .name and .plugins and (.plugins | length > 0)' "$$tmp/claude/.claude-plugin/marketplace.json" >/dev/null; \
	for f in $$(find "$$tmp" -name 'plugin.json' -type f); do \
	  jq -e '.name and .version and .description and .skills' "$$f" >/dev/null; \
	done; \
	rm -rf "$$tmp"

codex:
	CODEX_OUT="$(CODEX_OUT)" ./scripts/generate.sh codex

claude:
	CLAUDE_OUT="$(CLAUDE_OUT)" ./scripts/generate.sh claude

clean:
	rm -rf .codex-marketplace .claude-marketplace
