## Workflow

1. Run `scripts/artifacts.sh next-task`; if NONE, stop immediately.
2. Read the task, spec, decision, architecture, and accepted plan review; do not read unrelated files.
3. Reproduce an existing failure or write the smallest failing test/check at the seam using `references/test-first.md`; confirm the red result.
4. Implement the minimum production code required to satisfy the invariant using targeted hunk edits.
5. Rerun the same check until green, then run the task verify and broader suite; hand the code gate to `{{skill:review}}`.
6. Apply minimal review fixes; mark the task complete only after the test/verify and code review are accepted.
7. Stop; parent specs and decisions are derived from references.

## Quick change

Use only when the change is one file or a small reversible edit with a clear verify.

1. State the change and the failing check, if one is meaningful.
2. Make the minimal edit; no new public option, API, dependency, or artifact.
3. Run the verify. If it fails twice, stop.
4. No R/D/S/T artifacts; commit only when the user asks.

## Rules

- Test-first for non-trivial behavior, bugs, and changes with a real seam; trivial one-liners may use the task verify.
- Reproduce first; prove with the same command after the fix.
- Test the public seam, not the implementation; do not add tests that merely mirror code.
- `next-task` prints the task, spec, decision, and command context; do not load unrelated files.
- Respect accepted seam invariants; change internal implementation without breaking public boundaries.
- Apply minimal hunk edits; avoid unsolicited refactoring or premature abstractions.
- Never add design, spec, plan, or review breakdowns to a task.
- Do not start a task whose plan review is rejected; do not mark it complete without code review acceptance.
- Never mark parent specs or decisions complete.
- Verify: failing check went green, task verify passes, code review is accepted, and `artifacts/tasks.md` reflects `- [x] Txx`.
