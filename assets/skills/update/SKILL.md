## Workflow

1. Inspect workspace reality: `git status`, recent commits, manifests, build runners, and entrypoints.
2. Verify essential build, check, and test commands in the shell to confirm they pass.
3. Update `AGENTS.md` with verified commands, top-level layout, and conventions. Update `artifacts/context.md` (<60 lines) with architecture and module seams; never put commands there.
4. Reconcile RDST stack surgically in place using `sed -i` after executing verification commands:
   - Settle verified items: `sed -i 's/^- \[ \] \(T\|S\|D\|R\)xx:/- [x] \1xx:/' artifacts/{tasks,specs,decisions,requirements}.md`.
   - Record passing verification outputs on task lines in `artifacts/tasks.md`.
   - Update shifted seams in `artifacts/specs.md` and architectural consequences in `artifacts/decisions.md`.
5. Run `scripts/artifacts.sh verify-links` to ensure unbroken trace references (Rxx -> Dxx -> Sxx -> Txx).

## Rules

- Use surgical `sed -i` for flipping `- [ ]` to `- [x]` without re-writing entire artifact files.
- Reconcile all artifacts in one pass; never leave tasks, specs, decisions, or requirements desynchronized.
- Never mark an item `[x]` without running its verification check in the shell first.
- Keep requirement, decision, spec, and task IDs immutable; never renumber existing IDs.
- Preserve hand-written conventions in `AGENTS.md` and `artifacts/context.md`; let `AGENTS.md` grow with verified content, keep `artifacts/context.md` under 60 lines.
- Commands belong in `AGENTS.md` `## Essential Commands`; `artifacts/context.md` must not have a `## Commands` section.
- Verify: `scripts/artifacts.sh verify-links` outputs OK and all updated artifacts have verified status.
