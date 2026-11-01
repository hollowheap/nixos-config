## Workflow

1. Inspect workspace for `AGENTS.md` and `artifacts/context.md`. If `AGENTS.md` exists, stop immediately.
2. Inspect workspace manifests, source entrypoints, directory seams, and test runners directly; delegate repo recon to Scout and external research to Researcher only when the calling agent permits delegation.
3. Verify build, check, and test commands in the shell to confirm they pass.
4. Create `AGENTS.md` with a stack summary, `## Essential Commands`, `## Repository Layout`, `## Conventions`, and a `## Context` pointer.
5. Create `artifacts/context.md` with `## Stack & Entrypoints` and `## Module Seams`; commands belong only in `AGENTS.md`.
6. Create `artifacts/architecture.md` with current system, module, framework/library, data/contract, operations/security, debt, and evidence views.
7. Point `AGENTS.md` at `artifacts/context.md` and `artifacts/architecture.md`.

## Rules

- `AGENTS.md` contains only: title, stack summary, verified essential commands, top-level layout, conventions, workspace skills, and context/architecture pointers.
- Keep `AGENTS.md` scannable; let it grow with verified content. Keep `artifacts/context.md` under 60 lines.
- Record only verified build, check, and eval commands; run commands before writing.
- Document high-level module seams and boundary entrypoints, never internal functions.
- Verify: `AGENTS.md` has non-empty `## Essential Commands` and `## Repository Layout`; `artifacts/context.md` has non-empty `## Stack & Entrypoints` and `## Module Seams`; `artifacts/architecture.md` has system, module, framework/library, data/contract, and operations/security sections.
