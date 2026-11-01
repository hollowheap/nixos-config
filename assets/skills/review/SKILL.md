## Workflow

1. Choose the profile from `references/profiles.md`: `diff` by default, `slice` for a vertical slice, or `robust` for failure-mode or workspace audit. Add `references/ui.md`, `references/backend.md`, `references/security.md`, or `references/performance.md` only when the diff reaches rendered interfaces, transport/service boundaries, trust boundaries, or measured performance-sensitive paths.
2. Read the minimum inputs for that profile: diff = parent task/spec, changed hunks, and one verification; slice = `R/D/S/T`, the relevant architecture section, and the diff; robust = full relevant design, architecture, and evidence.
3. Run the always-on checks: correctness, security, simplicity/overengineering, traceability, and verification. Use `references/simplicity.md`; consult `references/gates.md` only for persistent slice or robust reviews.
4. Report findings with `file:line`. The diff profile reports high/medium findings inline, caps five, and stops when none remain; low notes are one line or omitted.
5. For persistent reviews, record or assign `Vxx` through `artifacts/reviews.md`, write the review document and RDST sections as needed, and register real design unknowns as `Qxx` under `### Review Vxx — <slice>`.
6. Apply minimal patches for blocking findings in the owning session; return to the owning skill when a section is rejected.
7. Re-run the section verification and record the accepted verdict.

## Rules

- Review still works by diff, slice, and robustness; UI, backend, security, and performance are optional lenses, not default phases.
- Diff review is ephemeral: no review document, no `Vxx`, and no RDST gate sections, unless a durable `Qxx` promotes it to a persistent review.
- Persistent review writes `Vxx` and may write RDST sections; review documents live in `artifacts/review/<slice>.md`.
- Review may write `Q` only for real design unknowns; never create `Dxx`, `Sxx`, or `Txx`; resolution remains `Qxx -> Dxx`.
- `deslop` is remediation only and runs on explicit request; review may recommend it.
- Simplicity/overengineering is always on; see `references/simplicity.md` and `artifacts/notes/reference-frameworks.md`.
- Correctness and security findings block; design findings block when they leave a required architecture category unresolved.
- Treat Code Reviewer as read-only; implement fixes directly in the owning session.
- Verify: profile inputs and checks are complete, `Vxx`/`Qxx` rules are followed, and verification commands pass.
