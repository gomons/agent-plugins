---
name: "git-create-worktree"
description: "Create a git worktree in the repository root under `.worktree/<branch-name>` from the current branch. Use when the user wants a new worktree and provides or implies the target branch name."
---

# Create Git Worktree

This skill creates a new git worktree for a new branch starting from the current branch `HEAD`.

## Required input

- A branch name. Treat it as required. If the user did not provide one, ask for it.

## Workflow

1. Confirm the current repository root:

```bash
git rev-parse --show-toplevel
```

2. Resolve the current branch for context:

```bash
git branch --show-current
```

3. Build the target path as:

```text
<repo-root>/.worktree/<branch-name>
```

4. Validate before creating:

- If `<repo-root>/.worktree/<branch-name>` already exists, stop and tell the user.
- If branch `<branch-name>` already exists locally, stop and tell the user unless the user explicitly asked to reuse an existing branch.
- If `.worktree/` does not exist, create it inside the repo root.

5. Create the worktree from the current branch `HEAD`:

```bash
mkdir -p "<repo-root>/.worktree"
git worktree add -b "<branch-name>" "<repo-root>/.worktree/<branch-name>" HEAD
```

This command creates a new branch from the currently checked out commit and checks it out in the new worktree.

## Response checklist

- Report the branch name that was created.
- Report the absolute path to the new worktree.
- Mention that the new branch was created from the current branch `HEAD`.

## Notes

- Do not create the worktree anywhere except `<repo-root>/.worktree/<branch-name>` unless the user explicitly asks for a different location.
- Prefer the exact command above over alternative flows so the branch is created from the current branch.
