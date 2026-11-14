---
name: ship-changes
description: Stage, commit, linearly merge worktree branches, or draft local PR descriptions when working with commits, worktrees, or PRs.
disable-model-invocation: false
agents: architect, engineer, worker
---

# Ship Changes

## Workflow

1. Run `git status`, `git diff`, and `git log --oneline -n 5` to inspect working state and out-of-session edits.
2. Route by request: load `references/worktree.md` only when integrating a worktree branch, or load `references/pr.md` only when drafting a PR description, then resume at step 3.
3. Scan diffs for exposed secrets, API keys, tokens, or credentials, and exclude unrelated changes.
4. Partition changes into atomic commits by vertical slice and complexity boundary; stage each slice explicitly by path (`git add <path>`) and never run `git add -A` or `git add .`.
5. Complete the requested action: create a signed conventional commit (`<type>(<scope>): <summary>`, `<=50` chars) per slice, finish linear worktree cleanup, or write a local PR description in `artifacts/pr/<branch>.md`.
6. Confirm `git status`, `git log -n 1 --show-signature`, or the written PR path is clean and accurate.

## Rules

- Never commit, merge, or push unless explicitly requested by the user; never create or open a remote PR (`gh pr create` etc.)—only draft locally so the user opens the PR remotely.
- Split multi-topic working trees into atomic commits along vertical slice and complexity boundaries; never bundle unrelated domains or concerns into one commit.
- Load `references/worktree.md` only for worktree merges and `references/pr.md` only for PR descriptions; skip both on normal commits.
- Never revert, amend, or reset out-of-session edits, force-push without `--force-with-lease`, create merge commits, or pass `--no-verify` or `--no-gpg-sign`.
- Keep commit messages, PR bodies, and any Markdown tables `<= 80` characters wide, and omit internal tracking IDs, scratch paths, or harness machinery.
- Verify: `git log -n 1 --show-signature` shows a signed conventional commit with empty `git diff --staged`, merged worktrees are absent from `git worktree list`, or `artifacts/pr/<branch>.md` matches `references/pr.md`.
