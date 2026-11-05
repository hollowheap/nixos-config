## Workflow

1. Run `scripts/artifacts.sh unconverted-decs`; if output is NONE, stop immediately.
2. Derive `Sxx` from accepted `Rxx`, `Dxx`, and the architecture view. If a parent or architecture section is missing, stop.
3. Probe ambiguous seams with the question tool; if an answer is unavailable, register `Qxx` in `artifacts/questions.md` under `### Specify — <slice>` and stop.
4. Run `scripts/artifacts.sh next-id s` to obtain sequential `Sxx` IDs.
5. Append public boundary invariants to `artifacts/specs.md` under the vertical-slice H3 heading and the `#### <Arch>` H4 group using `references/examples.md`; cite the accepted decision and architecture section.
6. Run `scripts/artifacts.sh check` to verify trace links and graph shape.

## Rules

- Every spec references a parent `Rxx` and accepted `Dxx`; never restate their text.
- Specify public seams and external behavioral invariants; never private implementation details.
- No stubs. If verification is not known from requirements, design, and architecture, stop and resolve the decision.
- Every spec declares an explicit verification command. Group specs under an H4 heading named exactly after the architecture H2; never repeat an `Arch:` field per spec.
- Never resolve an open question in a spec; create or amend an accepted decision instead.
- Never mark parent decisions complete; conversion is derived from references.
- Verify: `scripts/artifacts.sh check` outputs OK and `unconverted-specs` lists the new items.
