CODEX_OUT  := .codex-marketplace
CLAUDE_OUT := .claude-marketplace
PLUGINS    := rtk codanna serena git-tools

.PHONY: all codex claude clean

all: codex claude

codex:
	@for p in $(PLUGINS); do \
		mkdir -p $(CODEX_OUT)/plugins/$$p && \
		rsync -a --delete plugins/$$p/skills/ $(CODEX_OUT)/plugins/$$p/skills/ && \
		rsync -a           plugins/$$p/codex/  $(CODEX_OUT)/plugins/$$p/ ; \
	done
	cp marketplace/codex.json $(CODEX_OUT)/marketplace.json

claude:
	@for p in $(PLUGINS); do \
		mkdir -p $(CLAUDE_OUT)/plugins/$$p && \
		rsync -a --delete plugins/$$p/skills/  $(CLAUDE_OUT)/plugins/$$p/skills/ && \
		rsync -a           plugins/$$p/claude/ $(CLAUDE_OUT)/plugins/$$p/ ; \
	done
	cp marketplace/claude.json $(CLAUDE_OUT)/marketplace.json

clean:
	rm -rf $(CODEX_OUT) $(CLAUDE_OUT)
