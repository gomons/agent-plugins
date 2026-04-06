# Codanna Install

Use this skill when the Codanna binary may be missing from the machine and you want to install or verify it.

## Goals

- Ensure `codanna` is installed on the machine.
- Verify the binary is reachable from `PATH`.
- Confirm which executable will be used by the plugin launcher.

## Workflow

1. From the plugin root, run `./scripts/install_codanna.sh`.
2. Verify installation with `codanna --version`.
3. Verify resolution with `command -v codanna`.
4. If the current repository still needs Codanna project bootstrap, switch to the `codanna-init` skill.

## Notes

- The installer script prefers Codanna's official install script first, then falls back to Homebrew, Cargo, and Nix.
- This skill installs the binary only. Project initialization and index creation belong to the `codanna-init` skill.
- The plugin launcher only starts Codanna when the current project already has `.codanna/settings.toml` and a non-empty `.codanna/index/`.
- When that index exists, the launcher refreshes it with `codanna index` before starting the MCP server.
- If the project has never been initialized or indexed, the launcher intentionally does not run `codanna init` for you and exits with an explicit error so agents can understand why Codanna is unavailable.
- If installation succeeds but `codanna` still is not found, re-open the shell or update `PATH` to include the directory where Codanna was installed.
