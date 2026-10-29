## Workflow

1. Run `scripts/artifacts.sh next-task`; if NONE, stop immediately.
2. Review the printed commands, task, spec, decision, and seam invariants; do not read unrelated files.
3. Run the verification command first if checking existing behavior.
4. Implement minimum production code required to satisfy the invariant using targeted hunk edits.
5. Re-run task verification, then the broader test suite for regressions.
6. Mark only the task complete in `artifacts/tasks.md`: `- [x] Txx: ...`
7. Stop; parent specs and decisions are derived from references.

## Quick change

Use only when the change is one file or a small reversible edit with a clear verify.

1. State the change and the verify command in one line.
2. Make the minimal edit; no new public option, API, dependency, or artifact.
3. Run the verify. If it fails twice, stop.
4. No R/D/S/T artifacts; commit only when the user asks.

## Resume

- When the user says continue, run `next-task` first.
- If the current task is checked, skip it and start the next unblocked task.
- Never repeat completed steps or re-read context for a checked task.
- If no unblocked tasks remain, stop.

## Rules

- `next-task` prints the task, spec, decision, and command context; do not load unrelated files.
- Respect absorbed seam invariants: change internal implementation without breaking public boundaries.
- Apply minimal hunk edits; avoid unsolicited refactoring or premature abstractions.
- Write seam-based tests before implementation when a test runner exists.
- Mark task complete only after verification check command passes.
- Never mark parent specs or decisions complete.
- Stop immediately once verification passes.
- Verify: Task check command passes and `artifacts/tasks.md` reflects `- [x] Txx`.
