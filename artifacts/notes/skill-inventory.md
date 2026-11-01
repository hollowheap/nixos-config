# Skill Inventory

Persistent inventory and distillation map for every skill in the repo. Coverage: 23 skills. Harness matrix details live in `artifacts/notes/author-harness-matrices.md`. All are explicit user-invoked skills; descriptions are triggers, not automatic model invocation. Metadata lives in `home/lib/skill-metadata.nix`.

## Coverage matrix

| Skill | Role | Inputs | Outputs | Core principle | Distill |
|---|---|---|---|---|---|
| `brainstorm` | Discovery | Problem, repo seams, primary sources | `brainstorm.md`, candidate Qs | Compare archetypes; no implementation | keep as optional discovery mode |
| `design` | Requirements + design | Brainstorm, questions, architecture | `requirements.md`, accepted `Dxx`, architecture, design review | Outcomes before design; Q -> accepted D | keep |
| `specify` | Specification | Accepted `R/D`, architecture | `specs.md` with verify and `Arch` | Public invariants; no open Q | merge candidate with `plan` |
| `plan` | Delivery planning | Specs, review gate | `tasks.md` atomic tasks | One spec per task; no breakdown in tasks | merge candidate with `specify` |
| `implement` | Construction | Next task, spec, decision, architecture | Code, tests, task completion, code review | Test-first for non-trivial work; minimal vertical implementation | keep |
| `review` | Review | Diff/slice/robust scope, RDST, architecture | Findings, `Vxx` when persistent, optional Q | Diff/slice/robust profiles; simplicity always on; security/performance optional lenses | keep |
| `update` | Maintenance | Code reality, all artifacts | Reconciled architecture/RDST/review | Reconcile after verification; no ghost state | keep |
| `init` | Bootstrap | Repo manifests, commands, seams | `AGENTS.md`, `context.md`, `architecture.md` | Verified commands and seams only | keep one-time |
| `deslop` | Remediation | Explicit request, review evidence | Removed accidental complexity | Delete/inline; never add abstraction | keep explicit-only |
| `git-commit` | Delivery | Verified changes, diff | Signed commit | Explicit paths; no bypass; conventional message | keep |
| `merge-worktree` | Integration | Worker worktree, verification | Linear merge, task completion | No merge commit; verify before remove | keep |
| `modular-design` | Design reference | Module boundary question | Deep modules, ports, composition root | Vertical slices; dependencies inward | keep as reference |
| `retro` | Session retrospective | Active transcript | `retro.md` | Quantify execution; actionable adjustments | keep session-scoped |
| `author-pr` | Delivery writing | Branch diff | `artifacts/pr/<branch>.md` | Human-facing; no internal IDs or machinery | keep |
| `author-skill` | Meta authoring | Skill purpose, overlap, style | Skill body/references/metadata | One trigger; reference formats; verify build | keep meta |
| `author-harness` | Meta harness | Harness target, upstream shapes | Program module and native surfaces | Shared renderers; no harness-specific policy | keep |
| `overlap-check` | Meta audit | Candidate prompts, built-in coverage | Verified drop map | Drop only full overlap; measure | keep meta |
| `nix-flake-eval` | Nix verification | Flake changes, untracked files | Eval/build evidence | Stage explicit paths; full build exposes collisions | fold candidate into verification reference |
| `upstream-recon` | Upstream recon | Option/package path | Verified shapes, store evidence | Store source before web; no guesses | fold candidate into `author-harness` |
| `profile-author` | Device profile | Device config, loader | Profile bundle | No profile conditionals in modules | keep domain-specific |
| `selfhosted-service` | Service deployment | Daemon, Caddy, network | Loopback service + vhost | Loopback/mesh bind; no raw exposure | keep domain-specific |
| `session-audit` | Single-session audit | Transcript log | Loop diagnosis with step indices | Verbatim evidence; classify loop | merge into `corpus-audit` |
| `corpus-audit` | Multi-session audit | Compacted logs | `audit.md`, rule changes | Systemic patterns over incidents | keep; single-session mode candidate |

## Distillation candidates

### Strong candidates

- `specify` + `plan`: both convert accepted design into executable contracts. A distilled `design-to-plan` skill could keep two explicit gates but one workflow.
- `session-audit` -> `corpus-audit`: add a single-session mode instead of a separate skill.
- `upstream-recon` -> `author-harness`: make recon a required step/reference, not a standalone invocation.
- `nix-flake-eval` -> shared verification reference: keep the commands, fold the skill into `implement`/`author-harness` references if invocation cost is not justified.

### Keep separate

- `review` vs `deslop`: detection vs remediation.
- `retro` vs `session-audit`/`corpus-audit`: execution efficiency vs transcript-loop diagnosis.
- `design` vs `brainstorm`: design owns accepted decisions; brainstorm is optional pre-design exploration.
- `init` vs `update`: one-time bootstrap vs continuous reconciliation.
- `author-skill` vs `overlap-check`: authoring vs prompt-overlap audit.
- `git-commit` vs `author-pr`: commit integrity vs human-facing PR writing.
- `profile-author` vs `selfhosted-service`: device bundle vs service exposure.

### Do not add

The remaining reference-framework gaps—shared glossary and verification-skill maintenance—should become steps or references in existing skills, not new micro-skills. Global definition of done, multi-model interrogation, model routing, and a separate reproduce/fix/prove loop are rejected; testing and reproduction are part of `implement` test-first.

## Coverage checks

- Every skill directory has one inventory row.
- Every row names inputs, outputs, and a core principle.
- Distillation marks are `keep`, `merge`, `fold`, or `do not add`; none are implicit.
- All skills remain explicit and metadata-owned.
- `review` profiles, `Vxx` IDs, and `Qxx` writes are recorded in `review-model.md`.
- Cross-skill principles are recorded in `skill-principles.md`.
- External source distinctions are recorded in `reference-frameworks.md`.