## Workflow

1. Run `scripts/artifacts.sh unconverted-specs`; if NONE, run `unconverted-decs`.
2. Txx derives from Sxx. If a spec has no contract or verify, stop.
3. Challenge each task: what assumption does it carry, what would make it fail, and what proves it? Ask adaptively; do not batch when the next question depends on the answer.
4. Run `scripts/artifacts.sh next-id t` to obtain sequential Txx IDs.
5. Append atomic vertical tasks to `artifacts/tasks.md` (see examples). One spec per task by default; multiple only for a deliberate cross-cutting integration.
6. Run `scripts/artifacts.sh check` and then `scripts/artifacts.sh frontier`.

## Rules

- Every task references its parent Sxx. Blockers go in a trailing `[Txx, Tyy]`; omit the bracket when unblocked.
- No stubs. A task must have a verifiable outcome and command from the start.
- Keep tasks atomic; split a task that satisfies unrelated specs.
- Never mark parent specs or decisions complete; conversion is derived from references.
- Verify: `scripts/artifacts.sh check` outputs OK and `scripts/artifacts.sh frontier` lists ready tasks.
