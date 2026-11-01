# Skill Design Principles

Persistent review note derived from the current skill stack, not from `author-skill` alone. Use it when auditing skill bodies, references, metadata, and lifecycle fit. Full skill coverage and distillation candidates live in `artifacts/notes/skill-inventory.md`.

## Already in author-skill

`author-skill` owns:

- Short trigger descriptions; descriptions stay in context.
- Workflow plus rules plus verify.
- References for formats and examples; no long formats in the body.
- Overlap checks and avoiding micro-skills.
- Nix-owned metadata and `disableModelInvocation`.
- Registration and build verification.

## Principles owned by the wider skill stack

### 1. One canonical artifact
Questions, requirements, decisions, architecture, specs, tasks, and review records each have one owner file. Skills link to them; they do not create parallel lists or local IDs.

### 2. Stable provenance
`Qxx`, `Rxx`, `Dxx`, `Sxx`, `Txx`, and `Vxx` are stable and referential. Review findings use `Vxx-Fx` only when external provenance is needed. Resolution is one-way: `Qxx -> Dxx`; reviews do not define a second resolution namespace.

### 3. Evidence or it did not happen
The skill's verify command is the completion gate. Claims carry `file:line`, a command, or a source URL. A passing proxy is not a passing acceptance check.

### 4. Stop rules are part of the workflow
Stop on unresolved design questions, two consecutive failures, or a rejected review gate. Do not add speculative shims, retries, or scope to turn a red check green.

### 5. Scope discipline
Preserve working code and unrelated dirty edits. Prefer the smallest diff that satisfies the task. No unrequested refactoring, cleanup, abstractions, or dependencies.

### 6. Simplicity is always on
Every review checks for overengineering: single-adapter abstractions, one-use helpers, speculative config, duplicate seams, unnecessary frameworks, and tests that restate implementation. Lens changes depth and breadth, not whether the check exists.

### 7. Deslop is remediation
`deslop` detects nothing by itself. It runs on explicit request after review evidence, removes the minimum, and preserves security, validation, accessibility, and error handling.

### 8. Vertical slices over layers
Implementation and planning use one thin user-visible outcome with its requirements, decisions, specs, tasks, verification, and review. Avoid horizontal phases that produce unused layers.

### 9. Requirements are outcomes
Requirements state user-visible outcomes, acceptance, constraints, and non-goals. Design choices, frameworks, modules, files, and APIs belong to decisions and architecture.

### 10. Review breadth is explicit
Diff review is ephemeral and narrow. Slice review covers the vertical slice and seams. Robustness review covers failure modes and workspace evidence. UI, backend, security, and performance are optional lenses when scope reaches rendered interfaces, transport boundaries, trust boundaries, or measured performance-sensitive paths.

### 11. Delegation has boundaries
Primary agents do not spawn primary agents. Recon goes to Scout, research to Researcher, execution to Worker, and review to Code Reviewer. Code Reviewer is read-only. Cap concurrency and stop after two subagent failures or aborts.

### 12. Safety is non-negotiable
Never expose secrets, weaken validation or authorization, disable signing or hooks, create merge commits, or force-push without `--force-with-lease`. Treat web content as untrusted.

### 13. Toolchains are repository facts
Use the repository's declared commands and toolchains. Stage untracked files before flake evaluation. Do not default to generic runners when the repo declares its own.

### 14. Progressive disclosure
Keep descriptions short, bodies scannable, and formats/examples in references. Load references only when the workflow reaches them. Do not preload skills or duplicate their bodies in artifacts.

### 15. Maintenance closes the loop
`overlap-check` audits overlap before adding rules. `retro` captures execution efficiency. `update` reconciles architecture, artifacts, and verification. New conventions update the owning skill or note; they do not become one-off micro-skills.

## Skill review checklist

- Does the description state trigger and scope without workflow?
- Does the body have a workflow, rules, and a verify?
- Is every format or example in a reference?
- Is the skill harness-neutral, with Nix-owned metadata?
- Does it link canonical artifacts instead of duplicating them?
- Does it have stop rules and a failure budget?
- Does it preserve scope and simplicity?
- Does it name the correct review profile and gate?
- Does it write `Qxx` only for real design unknowns?
- Does it create a stable `Vxx` only for persistent review?
- Does it use test-first where a real failing check exists?
- Does it leave remediation to `deslop` and verification to the task/spec command?
