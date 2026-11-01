# Review Model

Persistent skill-authoring note for review profiles, IDs, and write rules.

## Review IDs

- Stable IDs use `Vxx`.
- Only persistent reviews receive one: robustness reviews, architecture/workspace audits, and durable slice reviews.
- Diff reviews are ephemeral and receive a `Vxx` only if they emit a durable `Qxx`.
- `artifacts/reviews.md` is the registry mapping `Vxx` to file, mode, and scope.

## Review profiles

### diff

- Inputs: parent task/spec, changed hunks, and one verification.
- No review document and no `Vxx`.
- Report high/medium findings inline; cap five.
- Token budget: no full architecture or review-history reads; no gate sections; stop when no high/medium findings remain; low notes are one line or omitted.

### slice

- Inputs: `R/D/S/T`, the relevant architecture section, and the diff.
- `Vxx` only if the review is durable.
- Simplicity is checked at seam and ownership.

### robust

- Inputs: full relevant design, architecture, and evidence.
- Always receives a `Vxx`.
- May write `Qxx`.

## Always-on checks

Correctness, security, simplicity/overengineering, traceability, and verification. Lenses change breadth and depth, not whether these checks exist.

## Simplicity checks

- single-adapter abstraction
- one-use helper
- speculative option or config
- duplicate validation or seam
- unnecessary framework or dependency
- test restating implementation
- deletion test

## deslop

`deslop` is remediation only. It runs on explicit request and is never auto-invoked. Review may recommend it.

## Question write rules

- Review may write `Qxx` to `artifacts/questions.md` under `### Review Vxx — <slice>`.
- Review never creates `Dxx`, `Sxx`, or `Txx`.
- No local review resolution IDs; resolution remains `Qxx -> Dxx`.

## Token budgets

- diff: no full architecture or review-history reads; no gate sections; stop at no high/medium findings; low notes one line or omitted.
- slice and robust: read only the relevant architecture section and review scope; persist `Vxx` and RDST sections only when durable.
