## Workflow

1. Run `git status` and `git diff`; read the parent Sxx and Rxx.
2. Choose the lens: `references/diff.md` by default; `references/slice.md` for a vertical slice; `references/robust.md` for failure modes; `references/ui.md` for rendered interfaces; `references/backend.md` for transport and services; `references/architecture.md` for ownership changes.
3. Delegate the chosen lens to Code Reviewer with the task spec, invariant, and report path.
4. Apply minimal patches for high or medium correctness or security findings.
5. Re-run task verification commands to confirm the suite remains green.

## Rules

- Review diffs against parent Sxx behavioral invariants.
- Correctness and security findings block; architecture findings do not block unless they violate Sxx.
- One adapter is a hypothetical seam; two adapters make it real. Never add a port for a single adapter.
- Treat Code Reviewer as read-only; implement fixes directly in the engineer session.
- Reject unsolicited refactoring, scope creep, and unrequested style cleanup.
- Verify: Zero high or medium correctness or security findings and verification suite passes.
