## Workflow

1. Run `scripts/artifacts.sh unconverted-decs`; if output is NONE, stop immediately.
2. Sxx derives from Rxx and Dxx. If either parent is missing, stop.
3. Probe ambiguous seams with the question tool: data shape, boundary, failure mode, and verification. Ask adaptively; the next question may depend on the answer.
4. Run `scripts/artifacts.sh next-id s` to obtain sequential Sxx IDs.
5. Append specs with public boundary invariants to `artifacts/specs.md` (see examples).
6. Run `scripts/artifacts.sh check` to verify trace links and graph shape.

## Rules

- Every spec references a parent Rxx and Dxx; never restate their text.
- Specify public seams and external behavioral invariants; never private implementation details.
- No stubs. If verification is not known from R and D, stop and resolve the decision.
- Every spec declares an explicit verification command (`Verify: <cmd>`).
- Never mark parent decisions complete; conversion is derived from references.
- Verify: `scripts/artifacts.sh check` outputs OK and `scripts/artifacts.sh unconverted-specs` lists new items.
