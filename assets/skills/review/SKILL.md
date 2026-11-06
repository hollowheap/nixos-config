## Workflow

1. Choose the profile from `references/profiles.md`: `diff` by default, `slice` for a vertical slice, or `robust` for failure-mode or workspace audit. When the diff reaches rendered interfaces, use `opal` only if the user invoked it. Add `references/backend.md`, `references/security.md`, or `references/performance.md` only when the diff reaches transport/service boundaries, trust boundaries, or measured performance-sensitive paths.
2. Read the minimum inputs: parent task/spec/decision, architecture section, changed hunks, and one verification.
3. Run the always-on checks: correctness, security, simplicity/overengineering, traceability, and verification. Use `references/simplicity.md`. For rendered interfaces, use `opal` when the user invokes it, and run its `ui-probe audit` and `ui-probe source` before judging; a UI review that never invokes the probe is incomplete. If `opal` is not active, say so and list rendered checks under unverified.
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
- UI work uses `opal` only when explicitly invoked. Cite the probe invocation and its summary; otherwise list every rendered check under unverified and state why.
- Correctness and security findings block task completion.
- Treat Code Reviewer as read-only; implement fixes directly in the owning session.
- Verify: profile inputs and checks are complete, `Vxx`/`Qxx` rules are followed, and verification commands pass.
