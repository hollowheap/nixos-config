## Workflow

1. Frame the destination: what changes for the user when this is done? Record it under `## Destination`.
2. Inspect the problem space, module seams, and directory structure.
3. If the domain is unfamiliar or contested, gather 2-3 primary sources via `references/research.md`; record evidence in `artifacts/research/<topic>.md` and link it under `## References`.
4. Register candidate unknowns in `artifacts/questions.md` under `### Brainstorm — <topic>`; do not duplicate question lists in the brainstorm artifact.
5. If feasibility probing is needed, write disposable scripts into `artifacts/scripts/`.
6. Formulate and compare 2-3 distinct architectural, code-organization, or UX archetypes against coupling, discoverability, blast radius, YAGNI, and failure modes.
7. Emit the recommendation and trade-off matrix to `artifacts/brainstorm.md` using `references/template.md`.

## Rules

- Research only when the domain is unfamiliar or contested; primary sources only, never a literature review.
- Design research lives in `artifacts/research/`; audit evidence lives in `artifacts/review/`.
- Explore structural trade-offs; never commit to implementation.
- Never edit production source files or git state; write test probes only to `artifacts/scripts/`.
- Always compare at least 2 contrasting alternatives with explicit failure modes.
- Questions are candidates for design, not decisions; design owns adaptive sequencing.
- Verify: `artifacts/brainstorm.md` has Destination, References, Archetypes, Trade-offs, Recommendation, an Open Questions pointer, and Out of scope.
