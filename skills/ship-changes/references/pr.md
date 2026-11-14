# Pull Request Format

Load only when drafting a PR description. Inspect `git log --oneline main..HEAD` and `git diff --stat main..HEAD`, choose the template that fits change size, and write `artifacts/pr/<branch>.md` locally so the user can open the PR remotely.

## Small Template (1-2 commits or narrow fix)

```markdown
# <PR title>

## Summary

One or two sentences: what changed and why.

## Key Changes

- Behavioral or config change one.
- Behavioral or config change two.
```

## Standard Template (multi-commit feature or refactor)

```markdown
# <PR title>

## TLDR

One or two sentences: what changes for the user and why.

## Motivation

Why this change is needed; two to three sentences.

## Key Changes

- Behavior and risk changes only; do not inventory every file.

## Breaking Changes & Migration

Explicit notes if options, paths, or dependencies changed; omit when none.
```

## Rules

- Never open or submit a remote PR (`gh pr create` etc.); only write the local PR file for the user.
- Use the actual PR title as the H1; never use `Pull Request Description`.
- Target human engineers; omit `Verification` sections, raw logs, traces, and unverified claims.
- Keep commands and file paths verbatim, and keep any Markdown tables `<= 80` characters wide.
