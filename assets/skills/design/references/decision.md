# Decision Record

Group accepted decisions under the exact architecture H2 heading: `### System Shape`, `### Module Seams`, `### Framework & Library Choices`, `### Data & Contracts`, or `### Operations & Security`.

### <Architecture H2>

- [x] Dxx [Rxx]: <accepted decision>
  - Context: <problem, constraints, and forces>
  - Alternatives: <rejected options and why>
  - Consequences: <what changes, what gets harder>
  - Resolves: <Qxx>        # only when closing a question
  - Supersedes: <Dyy>      # only when replacing a decision

## Rules

- Record accepted decisions only; unresolved choices stay in `questions.md`. An accepted decision may remain `[ ]` until its child specs complete.
- The H3 heading is the architecture reference; it must exactly match an H2 in `architecture.md`. Do not add a per-decision `Arch:` field.
- Verification belongs to child specs. Do not add a decision-level `Verify:` field.
- Include `Resolves` only when the decision closes a question; include `Supersedes` only when it replaces an earlier decision. Omit either field when it does not apply.
