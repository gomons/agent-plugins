CODEX_OUT  := .codex-marketplace
CLAUDE_OUT := .claude-marketplace
JSON_FILES := $(shell find marketplace plugins -name '*.json' -type f)
SH_FILES   := scripts/generate.sh plugins/codanna/skills/codanna-install/install_codanna.sh plugins/serena/skills/serena-install/install_serena.sh
BASH_FILES := plugins/rtk/skills/rtk-install/install_rtk.sh

.PHONY: all generate validate codex claude clean

all: generate validate codex claude

generate:
	./scripts/generate.sh

validate:
	@command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }
	@for f in $(JSON_FILES); do jq empty "$$f"; done
	@for f in $(SH_FILES); do sh -n "$$f"; done
	@for f in $(BASH_FILES); do bash -n "$$f"; done
	@before=$$(mktemp); after=$$(mktemp); \
	git diff -- marketplace plugins > "$$before"; \
	./scripts/generate.sh; \
	git diff -- marketplace plugins > "$$after"; \
	if ! cmp -s "$$before" "$$after"; then \
		echo "Generated files are out of date. Run make generate."; \
		diff -u "$$before" "$$after"; \
		rm -f "$$before" "$$after"; \
		exit 1; \
	fi; \
	rm -f "$$before" "$$after"

codex:
	@for p in $$(jq -r '.plugins[]' marketplace/source.json); do \
		mkdir -p $(CODEX_OUT)/plugins/$$p && \
		rsync -a --delete  plugins/$$p/codex/  $(CODEX_OUT)/plugins/$$p/ ; \
		rsync -a --delete plugins/$$p/skills/ $(CODEX_OUT)/plugins/$$p/skills/ ; \
	done
	cp marketplace/codex.json $(CODEX_OUT)/marketplace.json

claude:
	@for p in $$(jq -r '.plugins[]' marketplace/source.json); do \
		mkdir -p $(CLAUDE_OUT)/plugins/$$p && \
		rsync -a --delete  plugins/$$p/claude/ $(CLAUDE_OUT)/plugins/$$p/ ; \
		rsync -a --delete plugins/$$p/skills/  $(CLAUDE_OUT)/plugins/$$p/skills/ ; \
	done
	cp marketplace/claude.json $(CLAUDE_OUT)/marketplace.json

clean:
	rm -rf $(CODEX_OUT) $(CLAUDE_OUT)
