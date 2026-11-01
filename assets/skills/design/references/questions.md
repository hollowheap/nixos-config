# Questions

Questions are canonical in `artifacts/questions.md`. Do not duplicate them in brainstorm, requirements, decisions, specs, tasks, or reviews.

Group questions under meaningful H3 source headings. The heading owns the source, lens, and slice; each item carries only decision metadata.

```markdown
### Design — tray behavior
- [ ] Q01: Should the tray use the desktop option or a custom flag?
  - Scope: feature: tray behavior
  - Blocks: D01

### Review — AI harnesses (robust)
- [x] Q02: Should hooks fail closed on malformed payloads?
  - Scope: harnesses
  - Blocks: D66
  - Resolution: D66
```

## Rules

- Do not repeat `Origin`, `Lens`, or `Slice` per item.
- Use `Scope` only when it differs from the group.
- `Blocks` names a `Dxx`, `Sxx`, `Txx`, or `none`.
- Add `Resolution: Dxx` only after the decision is accepted; then mark the question `[x]`.
- Keep unresolved choices in this file; never record them as open `Dxx` entries.
