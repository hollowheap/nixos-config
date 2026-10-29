## Workflow

1. Run `git status`, `git diff`, and `git log --oneline -n 5` to inspect working tree state and foreign session edits.
2. Check diffs for exposed secrets, API keys, tokens, or private credentials before staging.
3. Stage intended task files explicitly by path; never run `git add -A` or `git add .`.
4. Commit with `<type>(<scope>): <imperative summary>` (<=50 chars, types: feat, fix, refactor, docs, test, chore, perf, ci, build, style).
5. Keep one verified logical change per commit; never rewrite shared git history.

## Rules

- Never commit unless explicitly requested by the user.
- Commit messages never mention internal RDST IDs, artifact paths, or harness machinery.
- Always stage explicit file paths; never use blanket `git add` commands.
- Check diffs for keys, tokens, and secrets before staging.
- Never revert, amend, or reset changes made outside the current session.
- Never force-push, delete remote branches, or rewrite history.
- Never pass --no-verify or --no-gpg-sign; never create merge commits. Rebase and integrate with --ff-only.
- Verify: `git log -n 1` shows conventional commit message and `git diff --staged` is clean.
