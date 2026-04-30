CODEX_OUT  := .codex-marketplace
CLAUDE_OUT := .claude-marketplace
JSON_FILES := $(shell find marketplace plugins -name '*.json' -type f)
SH_FILES   := $(shell find scripts plugins -name '*.sh' -type f)

.PHONY: all codex claude clean _check

all: codex claude

_check:
	@command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }
	@for f in $(JSON_FILES); do jq empty "$$f"; done
	@for f in $(SH_FILES); do bash -n "$$f"; done

codex: _check
	CODEX_OUT="$(CODEX_OUT)" ./scripts/generate.sh codex
	@jq -e '.name and .plugins and (.plugins | length > 0)' "$(CODEX_OUT)/.agents/plugins/marketplace.json" >/dev/null
	@for f in $$(find "$(CODEX_OUT)" -name 'plugin.json' -type f); do \
	  jq -e '.name and .version and .description and .skills' "$$f" >/dev/null; \
	done

claude: _check
	CLAUDE_OUT="$(CLAUDE_OUT)" ./scripts/generate.sh claude
	@jq -e '.["$$schema"] and .name and .plugins and (.plugins | length > 0)' "$(CLAUDE_OUT)/.claude-plugin/marketplace.json" >/dev/null
	@for f in $$(find "$(CLAUDE_OUT)" -name 'plugin.json' -type f); do \
	  jq -e '.name and .version and .description and .skills' "$$f" >/dev/null; \
	done

clean:
	rm -rf .codex-marketplace .claude-marketplace
