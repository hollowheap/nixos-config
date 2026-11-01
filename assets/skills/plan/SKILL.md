## Workflow

1. Run `scripts/artifacts.sh unconverted-specs`; if NONE, run `unconverted-decs`.
2. Derive `Txx` from `Sxx`. If a spec has no contract, architecture section, or verify command, stop.
3. Challenge each task with the question tool; if unresolved, register `Qxx` in `artifacts/questions.md` under `### Plan — <slice>`.
4. Run `scripts/artifacts.sh next-id t` to obtain sequential `Txx` IDs.
5. Append atomic vertical tasks to `artifacts/tasks.md` under the slice H3 heading using `references/examples.md`; keep the task record minimal.
6. Run `scripts/artifacts.sh check` and `scripts/artifacts.sh frontier`.
7. Hand the plan gate to `{{skill:review}}`; record its section in `artifacts/review/<slice>.md` before implementation.

## Rules

- Every task references its parent `Sxx`. Put blockers in a trailing `[Txx, Tyy]`; omit the bracket when unblocked.
- Keep tasks minimal: outcome, verify, files, notes, risk. Do not add requirements, design, spec, or review breakdowns.
- No stubs. A task must have a verifiable outcome and command from the start.
- Keep tasks atomic; split a task that satisfies unrelated specs.
- Never mark parent specs or decisions complete; conversion is derived from references.
- Verify: `scripts/artifacts.sh check` outputs OK, `frontier` lists ready tasks, and the plan review section is accepted.
