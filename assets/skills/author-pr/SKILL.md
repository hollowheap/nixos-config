## Workflow

1. Inspect branch changes against the base branch:
   - `git log --oneline main..HEAD`
   - `git diff --stat main..HEAD`
2. Draft the PR description using `references/format.md`.
3. Write it to `artifacts/pr/<branch>.md`; present the path to the user.

## Rules

- Target human engineers.
- PR descriptions never mention internal RDST IDs, artifact paths, or harness machinery.
- TLDR first; Key Changes lists behavior and risk, not every touched file.
- No Verification section; tests are already covered by the task.
- Never dump logs, traces, or unverified claims.
- Commands and file paths must be verbatim.
- Verify: `artifacts/pr/<branch>.md` exists and follows `references/format.md`.
