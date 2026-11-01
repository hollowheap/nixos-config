## Workflow

1. Run `scripts/artifacts.sh status`; read `artifacts/requirements.md`, `artifacts/questions.md`, `artifacts/architecture.md`, and `artifacts/brainstorm.md` when present.
2. Convert observable outcomes into requirements using `references/requirements.md`, grouped by vertical-slice H3 headings; reject any requirement that names a framework, module, file, or API.
3. Grill adaptively with the question tool; register candidate unknowns in `artifacts/questions.md` under an H3 source heading with `references/questions.md`; never create a local question list.
4. Record accepted decisions with `references/decision.md`, grouped under the H3 architecture category, and cite `Resolves: Qxx` when a decision closes a question.
5. Update `artifacts/architecture.md` with `references/architecture.md` for accepted design changes; link the decision and keep the current-state view current.
6. Hand the requirements and design gates to `{{skill:review}}`; require the sections in `artifacts/review/<slice>.md` before specifying.
7. Close resolved questions with `Resolution: Dxx`; leave unresolved choices open. Stop at accepted design and architecture.

## Rules

- Requirements describe observable outcomes, acceptance, constraints, and non-goals; never implementation choices.
- Decisions are accepted only. Unresolved choices remain `Qxx`; an accepted decision may stay `[ ]` until its child specs complete.
- Design covers system shape, module seams, framework and library choices, data contracts, and operations.
- A question's H3 heading owns its source; do not repeat `Origin`, `Lens`, or `Slice` per item.
- Any behavior-changing decision made in chat becomes an accepted `Dxx` before the next action. If it has no parent `Rxx`, stop and ask for the requirement.
- `Sxx` derives from accepted `Rxx`, `Dxx`, and architecture; `Txx` derives from `Sxx`.
- Verify: requirements contain no design choices, questions are grouped by source, no orphaned open decisions exist, architecture is current, and the design review section is accepted.
