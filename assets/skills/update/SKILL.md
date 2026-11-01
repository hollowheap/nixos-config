## Workflow

1. Inspect workspace reality: `git status`, recent commits, manifests, build runners, and entrypoints.
2. Verify essential build, check, and test commands in the shell to confirm they pass.
3. Update `AGENTS.md` with verified commands and conventions; update `artifacts/context.md` with module seams and the architecture pointer.
4. Reconcile `artifacts/architecture.md` with accepted decisions; refresh system, module, framework/library, data/contract, and operations/security views.
5. Reconcile questions and decisions: unresolved choices stay in `artifacts/questions.md`; accepted decisions carry `Resolves` and `Resolution`; no orphaned `Dxx` remains.
6. Reconcile requirements, specs, and tasks in place after executing their verification commands; keep task records minimal.
7. Run `scripts/artifacts.sh verify-links` and refresh review gate verdicts for changed slices.

## Rules

- Use surgical `sed -i` for flipping `- [ ]` to `- [x]` without rewriting entire artifact files.
- Never mark an item `[x]` without running its verification check in the shell first.
- Do not keep orphaned open decisions; unresolved choices belong in `questions.md`, while accepted decisions may stay open until child specs complete.
- Keep requirement, decision, spec, and task IDs immutable; never renumber existing IDs.
- Keep `AGENTS.md` verified and scannable; keep `artifacts/context.md` under 60 lines.
- Commands belong in `AGENTS.md` `## Essential Commands`; `artifacts/context.md` must not have a `## Commands` section.
- Verify: `scripts/artifacts.sh verify-links` outputs OK, architecture is current, no orphaned open decisions remain, and review gates reflect the changed slices.
