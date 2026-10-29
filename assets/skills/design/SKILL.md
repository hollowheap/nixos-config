## Workflow

1. Run `scripts/artifacts.sh status`; if uninitialized, stop.
2. Read `artifacts/brainstorm.md` if present; carry Destination, Recommendation, `Qxx` questions, and Out of scope as a frontier, not a fixed questionnaire. Ask what and why; scout repo facts. Do not run audits here.
3. Grill adaptively: treat `Qxx` as an unordered frontier. Ask the next most informative question, add a `Qxx` when a new unknown appears, and resolve or defer after each answer. Cover data shape, boundary, failure modes, verification, and the smallest change. Delegate facts; decisions are the user's.
4. Record requirements in `artifacts/requirements.md` as observable outcomes with acceptance.
5. Record decisions in `artifacts/decisions.md` referencing parent `[Rxx]`, using `references/decision.md`.
6. Leave unresolved questions under `## Open Questions` in `artifacts/requirements.md` with stable `Qxx` IDs.

## Rules

- Any behavior-changing decision made in chat becomes a Dxx before the next action. If it has no parent Rxx, stop and ask for the requirement.
- Sxx derives from Rxx and Dxx; Txx derives from Sxx. Design stops at D.
- Record a Dxx when the choice is hard to reverse, surprising without context, or trades off real alternatives. Routine choices belong in Sxx or implementation.
- Requirements describe observable outcomes and acceptance, never file paths or internal functions.
- Never dump the `Qxx` list as a batch; IDs preserve traceability, not question order.
- Verify: `artifacts/requirements.md` has open `- [ ] Rxx` items and `artifacts/decisions.md` has `- [ ] Dxx [Rxx]` items.
