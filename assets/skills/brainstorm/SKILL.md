## Workflow

1. Frame the destination: what changes for the user when this is done? Record it under `## Destination`.
2. Inspect the problem space, module seams, and directory structure.
3. If the domain is unfamiliar or contested, gather 2-3 primary sources via `references/research.md`; record evidence in `artifacts/research/<topic>.md` and link it under `## References`.
4. Map `## Open Questions` with stable `Qxx` IDs and `## Out of scope`; keep unknowns explicit.
5. If feasibility probing is needed, write disposable scripts into `artifacts/scripts/`.
6. Formulate 2-3 distinct architectural, code-organization, or UX archetypes.
7. Evaluate archetypes against coupling, discoverability, blast radius, YAGNI, and failure modes.
8. Emit the trade-off matrix and recommended direction to `artifacts/brainstorm.md` using `references/template.md`.

## Rules

- Research only when the domain is unfamiliar or contested; primary sources only, never a literature review.
- Design research lives in `artifacts/research/`; audit evidence lives in `artifacts/review/`.
- Technical archetype stance: explore structural trade-offs; never commit to implementation.
- Invariant: Never edit production source files or git state; write test probes only to `artifacts/scripts/`.
- Always compare at least 2 contrasting alternatives with explicit failure modes.
- Open Questions are candidate unknowns; design owns adaptive sequencing.
- Verify: `artifacts/brainstorm.md` has Destination, References, Archetypes, Trade-offs, Open Questions, and Out of scope.
