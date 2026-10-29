# Diff Review Lens

Use for every patch review unless a more specific lens applies.

## Workflow

1. Read the parent Sxx and Rxx before opening the diff.
2. Run `git status` and `git diff`; identify behavior changes, not just file churn.
3. Check correctness, regressions, error paths, secret leaks, type safety, and boundary contracts.
4. Reproduce every high-impact claim with a command; cite `file:line` for each finding.
5. Apply minimal patches for high or medium correctness or security findings.
6. Re-run the task verification, then the broader suite.

## Rules

- Never rewrite the patch wholesale; target the smallest failing seam.
- Do not add tests that merely restate the implementation.
- Treat Code Reviewer as read-only; implement fixes in the engineer session.
- Verify: zero high or medium correctness or security findings and the verification suite passes.
