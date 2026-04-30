---
name: "serena-init"
description: "Activate the current repository in Serena after the Serena MCP server is running, and perform onboarding if Serena has not seen the project before."
---

# Serena Init

Use this skill when Serena is installed and the MCP server is available, but the current repository still needs to be activated in Serena.

## Goals

- Activate the current project in Serena.
- Check whether Serena onboarding has already been completed.
- Run onboarding when needed so Serena can work effectively in this repository.

## Workflow

1. Confirm that the Serena MCP server is available. If it is not, switch to `serena-install`.
2. Activate the current repository with the Serena `activate_project` tool.
3. Call `check_onboarding_performed`.
4. If onboarding is missing, call `onboarding` once for the project.
5. Confirm that Serena is ready for semantic code inspection and editing in the current repository.

## Notes

- This skill prepares the current repository for Serena usage in the current Codex session.
- Unlike Codanna, Serena does not require a repository-local `.serena/` bootstrap directory here.
