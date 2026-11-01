# Review Profiles

## Profile matrix

| Profile | Inputs | Persistent? | Vxx | RDST sections | Q writes |
|---|---|---|---|---|---|
| diff | parent task/spec, changed hunks, one verification | no | only if durable Qxx | no | only by promoting to Vxx |
| slice | `R/D/S/T`, relevant architecture section, diff | only if durable | only if durable | optional | real design unknowns only |
| robust | full relevant design/architecture/evidence | yes | always | yes | may write |

## Review IDs

- Stable IDs are `Vxx`.
- Only persistent reviews receive one: robustness, architecture/workspace audit, durable slice review.
- Diff reviews are ephemeral and receive `Vxx` only if they emit a durable `Qxx`.
- `artifacts/reviews.md` maps `Vxx` to file, mode, and scope.

## Q-write rules

- Review may write `Qxx` to `artifacts/questions.md` under `### Review Vxx — <slice>`.
- Review never creates `Dxx`, `Sxx`, or `Txx`.
- No local review resolution IDs; resolution remains `Qxx -> Dxx`.

## Optional lenses

- UI: rendered interfaces.
- Backend: transport and service boundaries.
- Security: trust boundaries, auth, secrets, exposure, persistence.
- Performance: hot paths, large data, startup, repeated work, measured regressions.

## Token budget

- diff: no full architecture or review-history reads; no gate sections; stop at no high/medium findings; low notes one line or omitted.
- slice/robust: read only the relevant architecture section and review scope; persist `Vxx` and RDST sections only when durable or required.

## Simplicity checks

See `references/simplicity.md`. Always on for every profile; lenses change breadth and depth, not whether the check exists.
