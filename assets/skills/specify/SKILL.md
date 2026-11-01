## Workflow

1. Run `scripts/artifacts.sh unconverted-decs`; if output is NONE, stop immediately.
2. Derive `Sxx` from accepted `Rxx`, `Dxx`, and the architecture view. If a parent or architecture section is missing, stop.
3. Probe ambiguous seams with the question tool; if an answer is unavailable, register `Qxx` in `artifacts/questions.md` under `### Specify — <slice>` and stop.
4. Run `scripts/artifacts.sh next-id s` to obtain sequential `Sxx` IDs.
5. Append public boundary invariants to `artifacts/specs.md` under the vertical-slice H3 heading using `references/examples.md`; cite the accepted decision and architecture section.
6. Run `scripts/artifacts.sh check` to verify trace links and graph shape.
7. Hand the specification gate to `{{skill:review}}`; record its section in `artifacts/review/<slice>.md` before planning.

## Rules

- Every spec references a parent `Rxx` and accepted `Dxx`; never restate their text.
- Specify public seams and external behavioral invariants; never private implementation details.
- No stubs. If verification is not known from requirements, design, and architecture, stop and resolve the decision.
- Every spec declares an explicit verification command. `Arch` is the exact architecture H2 name, never a path or anchor.
- Never resolve an open question in a spec; create or amend an accepted decision instead.
- Never mark parent decisions complete; conversion is derived from references.
- Verify: `scripts/artifacts.sh check` outputs OK, `unconverted-specs` lists the new items, and the specification review section is accepted.
