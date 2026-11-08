## Workflow

1. Choose the profile from `references/profiles.md`: `diff` by default, `slice` for a vertical slice, or `robust` for failure-mode or workspace audit. Add `references/backend.md`, `references/security.md`, or `references/performance.md` only when the diff reaches transport/service boundaries, trust boundaries, or measured performance-sensitive paths.
2. Read the minimum inputs: parent task/spec/decision, architecture section, changed hunks, and one verification.
3. Run the always-on checks: correctness, security, simplicity/overengineering, traceability, and verification. Use `references/simplicity.md`. Rendered checks run only when the user invokes `opal`; otherwise list them under unverified and say why.
4. Report findings with `file:line`. The diff profile reports high/medium findings inline, caps five, and stops when none remain; low notes are one line or omitted.
5. For persistent reviews, record or assign `Vxx` through `artifacts/reviews.md` and write the review document. Record findings only; do not add phase gates.
6. Apply minimal patches for blocking findings in the owning session.
7. Re-run the task verification and record the verdict.

## Rules

- Review runs after implementation. It does not gate requirements, design, specification, or planning.
- Review still works by diff, slice, and robustness; UI, backend, security, and performance are optional lenses.
- Diff review is ephemeral: no review document and no `Vxx`, unless a durable `Qxx` promotes it to a persistent review.
- Persistent review writes `Vxx`; review documents live in `artifacts/review/<slice>.md` and contain findings, not phase checklists.
- Review may write `Q` only for real design unknowns; never create `Dxx`, `Sxx`, or `Txx`; resolution remains `Qxx -> Dxx`.
- `deslop` is remediation only and runs on explicit request; review may recommend it.
- Simplicity/overengineering is always on; see `references/simplicity.md` and `artifacts/notes/reference-frameworks.md`.
- Rendered checks require the user to invoke `opal`; cite its summary when they do, otherwise mark them unverified.
- Correctness and security findings block task completion.
- Treat Code Reviewer as read-only; implement fixes directly in the owning session.
- Verify: profile inputs and checks are complete, `Vxx`/`Qxx` rules are followed, and verification commands pass.
