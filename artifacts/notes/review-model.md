# Review Model

Authoritative review rules live in the `iridescent` skill source (`skills/review/`
in `github:hollowheap/iridescent`):

- Profiles, review IDs, Q writes, and token budgets: `SKILL.md` and `references/profiles.md`.
- Always-on simplicity checks: `references/simplicity.md`.
- Lenses and the lens ledger: `references/{backend,security,performance,ui}.md` and `references/profiles.md`.

Review writes findings, not phase gates. `artifacts/reviews.md` maps persistent
`Vxx` IDs to review files. `deslop` remediation is owned by `skills/deslop/SKILL.md`
in the same source.
