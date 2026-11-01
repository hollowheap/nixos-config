# Reference Framework Analysis

Persistent skill-authoring note. Simplicity is one axis; the reference frameworks contribute separate principles, and only some fit this stack. This note is the single equal-depth analysis of the four frameworks. It replaces the narrower simplicity note.

## Scope and attribution rules

- Frameworks analyzed: Ponytail / Dietrich Gebert, Matt Pocock, Addy Osmani, pstack / Lauren Tan.
- Evidence order: official repository or docs first, then reputable secondary summaries. Secondary claims are marked `(secondary)` or `(inferred)`.
- Direct rules are attributed only where the source states or clearly demonstrates them. Adapted rules are our synthesis. No source is claimed to endorse every rule in this note.
- Statuses: `adopted`, `adapted`, `partial`, `missing`, `rejected`, `not applicable`.
- Frameworks are not imported wholesale. Each principle is mapped to an existing skill, artifact, or an explicit design decision.
- Simplicity is one axis, not the whole framework set.

## 1. Ponytail / Dietrich Gebert

### Source and evidence links

- Docs: https://ponytail.dev/docs
- Repo: https://github.com/DietrichGebert/ponytail
- Secondary: https://dev.to/arshtechpro/ponytail-the-ai-coding-skill-that-makes-your-agent-write-less-code-29l3
- Secondary: https://blog.stackademic.com/does-the-ponytail-skill-actually-improve-claude-code-or-just-cut-its-line-count-9e2f31a3b32a

### Core thesis / operating model

Ponytail is a code-minimization decision procedure. Before writing, the agent walks a ladder from "does this need to exist?" to "the minimum that works"; the first rung that holds wins. The framing is "lazy senior developer": optimize for fewer lines, but never by cutting validation, security, accessibility, or error handling.

### Direct principles and mechanics

- Lazy-senior ladder:
  1. Does this need to exist? If no, skip it (YAGNI).
  2. Is it already in this codebase? Reuse it.
  3. Does stdlib do it? Use stdlib.
  4. Is there a native platform feature? Use it.
  5. Is an already-installed dependency sufficient? Use it.
  6. Can it be one line? Write one line.
  7. Otherwise, write the minimum that works.
- YAGNI.
- Reuse existing repo code before rewriting.
- Prefer stdlib, native platform features, and installed dependencies before new code.
- One line when possible.
- Minimum code.
- No unrequested abstractions, dependencies, or boilerplate.
- Deletion over addition (direct in our prior extraction; treat as Ponytail-derived, not independently verified in the README excerpt).
- Mark deliberate shortcuts with their ceiling.
- Preserve validation, security, accessibility, and error handling; these are never on the chopping block.
- Leave one runnable check for non-trivial logic.
- "Lazy, not negligent": trust-boundary validation, data-loss handling, security, and accessibility are non-negotiable.

### What we adopt, adapt, or reject

- Adopt: YAGNI, reuse-first, dependency discipline, one-line preference, minimum code, safety preservation, runnable check.
- Adapt: the ladder becomes review simplicity checks and deslop criteria rather than a persona; deletion becomes the deletion test.
- Reject or avoid: persona framing as a default operating mode; line-count reduction as a success metric by itself; applying the ladder to architecture or safety decisions where removal is not appropriate.

### Coverage in our skill stack

- `review`: simplicity checks and deletion test.
- `deslop`: candidate proof and removal criteria.
- `implement`: minimal patches and verification.
- `modular-design`: "one adapter is hypothetical; two adapters make the seam real."

### Boundaries / things not to overattribute

- Ponytail is a code-minimization skill. It is not an architecture framework, review-ID system, RDST spine, security checklist, or module-depth guide.
- Do not attribute deep modules, two-axis review, five-axis review, TDD, ADRs, or operational verification to Ponytail.
- "Deletion over addition" is carried as Ponytail-derived; if a stricter audit is needed, verify against the upstream docs before citing it as a direct quote.

## 2. Matt Pocock

### Source and evidence links

- Repo: https://github.com/mattpocock/skills
- Skills analyzed:
  - https://github.com/mattpocock/skills/blob/main/skills/engineering/codebase-design/SKILL.md
  - https://github.com/mattpocock/skills/blob/main/skills/engineering/code-review/SKILL.md
  - https://github.com/mattpocock/skills/blob/main/skills/engineering/tdd/SKILL.md
  - https://github.com/mattpocock/skills/blob/main/skills/engineering/diagnosing-bugs/SKILL.md
  - https://github.com/mattpocock/skills/blob/main/skills/engineering/implement/SKILL.md
  - https://github.com/mattpocock/skills/blob/main/skills/engineering/to-spec/SKILL.md
  - https://github.com/mattpocock/skills/blob/main/skills/engineering/to-tickets/SKILL.md
  - https://github.com/mattpocock/skills/blob/main/skills/engineering/grill-with-docs/SKILL.md
- Secondary: https://www.ai.joaoqueiros.com/blog/matt-pocock-ai-coding-skills-grill-spec-ticket-review
- Secondary: https://www.aihero.dev/skills-implement

### Core thesis / operating model

Pocock's model moves human judgment to the cheapest stage of the workflow. A vague idea becomes clarified decisions, then a spec, then tracer-bullet tickets, then tested implementation, then independent code review. Each artifact lowers ambiguity for the next context window and makes work portable, inspectable, and resumable. The core engineering primitives are deep modules, small feedback loops, and two-axis review.

### Direct principles and mechanics

- Grill with docs: resolve the design tree before building; develop shared terminology; update `GLOSSARY.md` and ADRs inline.
- Grilling is adaptive and question-driven; it sharpens language and records decisions.
- Deep modules: a lot of behavior behind a small interface, at a clean seam, testable through that interface.
- Architecture survey: scan for deepening opportunities and present them as a report, then grill through the chosen one.
- Small feedback steps: static types, browser access, automated tests; the rate of feedback is the speed limit.
- TDD: red-green-refactor, one vertical slice at a time, good versus bad tests, DAMP over DRY where appropriate.
- Diagnosing bugs: build a feedback loop that goes red on the bug, then minimize, hypothesize, instrument, fix, and add a regression test.
- to-spec: synthesize an already-discussed conversation into a spec without another interview.
- to-tickets: break a plan or spec into tracer-bullet tickets with blocking edges and acceptance evidence.
- implement: build from a spec or ticket set, drive TDD at pre-agreed seams, close out with code review before commit.
- code-review: two axes, Standards and Spec, run as parallel sub-agents so neither pollutes the other.
- Standards axis: repository coding standards plus a Fowler smell baseline.
- Spec axis: faithful implementation of the originating issue or spec.
- Remove no-op instructions: wording that does not change model behavior should be deleted or replaced with concrete triggers, constraints, checks, or output contracts.
- Shared vocabulary and durable decisions are part of the design artifact, not chat residue.

### What we adopt, adapt, or reject

- Adopt: artifact chain, deep modules, two-axis review, vertical tickets, red-green-refactor, bug diagnosis loop, no-op instruction pruning.
- Adapt: tracker-based tickets map to our `Txx` tasks; code-review axes map to our review profiles and gates; grilling maps to `design` questions and adaptive `Qxx` handling; `GLOSSARY.md` maps to a candidate shared-language artifact.
- Reject or avoid: duplicating a tracker-centric workflow when RDST artifacts already own state; model-invoked versus user-invoked skill distinctions where our metadata already governs invocation; assuming tests exist before specifying them.

### Coverage in our skill stack

- `brainstorm`: discovery and candidate questions.
- `design`: outcomes, accepted `Dxx`, architecture, adaptive questions.
- `specify`: public invariants and verify commands.
- `plan`: atomic tasks and dependencies.
- `implement`: minimal vertical implementation and verification.
- `review`: diff, slice, and robustness profiles; standards and spec axes.
- `modular-design`: deep modules, seams, composition roots.
- `deslop`: no-op and accidental-complexity removal.

### Boundaries / things not to overattribute

- Pocock contributes engineering workflow, module depth, TDD, and two-axis review. He does not provide the Ponytail ladder, Chesterton's Fence, Rule of 500, or pstack's verification machinery.
- "Two-axis review" is Pocock-specific; our review also has always-on correctness, security, simplicity, traceability, and verification checks.
- Pocock's issue-tracker workflow is an implementation detail; our canonical artifacts remain the source of truth.

## 3. Addy Osmani

### Source and evidence links

- Repo: https://github.com/addyosmani/agent-skills
- Skills analyzed:
  - https://github.com/addyosmani/agent-skills/blob/main/skills/code-simplification/SKILL.md
  - https://github.com/addyosmani/agent-skills/blob/main/skills/code-review-and-quality/SKILL.md
  - https://github.com/addyosmani/agent-skills/blob/main/skills/constraint-driven-development/SKILL.md
  - https://github.com/addyosmani/agent-skills/blob/main/skills/incremental-implementation/SKILL.md
  - https://github.com/addyosmani/agent-skills/blob/main/skills/test-driven-development/SKILL.md
  - https://github.com/addyosmani/agent-skills/blob/main/skills/documentation-and-adrs/SKILL.md
  - https://github.com/addyosmani/agent-skills/blob/main/skills/security-and-hardening/SKILL.md
  - https://github.com/addyosmani/agent-skills/blob/main/skills/performance-optimization/SKILL.md
- Secondary: https://addyo.substack.com/p/agentic-code-quality
- Secondary: https://addyosmani.com/blog/agentic-code-review/

### Core thesis / operating model

Osmani's model treats software quality as constraints and back-pressure around agent output. Writing code became cheap; judgment and verification did not. Quality gates should run throughout the pipeline, not only at final review. Agent-generated PRs are larger and require layered review, careful test inspection, and explicit quality bars. Review is now a trust-building system, not a line-by-line habit.

### Direct principles and mechanics

- Constraint-driven development: interview for a quality bar, write `CONSTRAINTS.md`, place each check by cost, and catch agents silencing checks or skipping tests to get green.
- Incremental implementation: thin vertical slices; implement, test, verify, commit; feature flags, safe defaults, rollback-friendly changes.
- TDD: red-green-refactor, test pyramid (80/15/5), test sizes, DAMP over DRY, Beyonce Rule, browser testing.
- Code review and quality: five-axis review, change sizing around 100 lines, severity labels (Nit/Optional/FYI), review speed norms, splitting strategies.
- Code simplification: Chesterton's Fence, Rule of 500, reduce complexity while preserving exact behavior.
- Security and hardening: OWASP Top 10 prevention, auth patterns, secrets management, dependency auditing, three-tier boundary system.
- Performance optimization: measure-first approach, Core Web Vitals targets, profiling workflows, bundle analysis, anti-pattern detection.
- Documentation and ADRs: document why, not just what.
- Spec-driven development: PRD covering objectives, commands, structure, code style, testing, and boundaries before code.
- Source-driven development: ground framework decisions in official documentation, verify, cite sources, flag unverified claims.
- Doubt-driven development: adversarial fresh-context review using CLAIM, EXTRACT, DOUBT, RECONCILE, STOP, with optional user-authorized cross-model escalation.
- Shipping and launch: pre-launch checklists, feature-flag lifecycle, staged rollouts, rollback procedures.
- Deprecation and migration: safe migration patterns.
- Observability and debugging/error-recovery skills.
- Agentic review guidance: read test changes more carefully than code; treat rewritten tests as a flag; use mutation testing; fast-fail expensive PRs; layered review by risk; human understanding is the durable advantage.

### What we adopt, adapt, or reject

- Adopt: quality bar, incremental slices, five-axis review, change sizing, Chesterton's Fence, Rule of 500, behavior preservation, ADRs, security/performance checklists, source-driven verification, doubt-driven review for high stakes.
- Adapt: five axes map to our always-on checks; ~100-line sizing maps to atomic tasks and review diff caps, not a hard metric; `CONSTRAINTS.md` maps to requirements, decisions, specs, and verify commands; security and performance become optional lenses rather than default phases.
- Reject or avoid: importing all 25 skills; agent personas as default reviewers; treating green tests as proof without inspecting test edits; replacing human understanding with automation.

### Coverage in our skill stack

- `design`: outcomes, constraints, non-goals, accepted decisions.
- `specify`: public invariants, verify commands, architecture sections.
- `plan`: atomic tasks and dependencies.
- `implement`: minimal vertical slices and verification.
- `review`: correctness, security, simplicity, traceability, verification; optional UI/backend lenses.
- `deslop`: Chesterton's Fence and behavior preservation.
- `update`: reconciliation and architecture currency.
- `upstream-recon`: source-driven verification from store/docs.
- `modular-design`: interface and dependency discipline.

### Boundaries / things not to overattribute

- Osmani contributes quality constraints, review axes, and verification discipline. He does not provide the Ponytail ladder or Pocock's deep-module and grilling model.
- "Five-axis review" is Osmani-specific; our review axes are adapted to this repository's always-on checks and profiles.
- Osmani's broader skill catalog includes shipping, observability, frontend, API design, CI/CD, and migration; only the requested subset is analyzed here, so claims about the rest are inferred from the repository overview, not from direct skill reads.

## 4. pstack / Lauren Tan

### Source and evidence links

- Repo path: https://github.com/cursor/plugins/tree/main/pstack
- README: https://github.com/cursor/plugins/blob/main/pstack/README.md
- Secondary: https://daily.dev/posts/a-deep-dive-into-pstack-evqbnto9j
- Secondary: https://azukiazusa.dev/en/blog/pstack-agent-skills/
- Secondary: https://flaviocopes.com/pstack/
- Secondary: https://redreamality.com/garden/notes/pstack-skills-guide/

### Core thesis / operating model

pstack is an operational engineering workflow for coding agents. Its stated goal is to write less, but higher-quality code. It combines workflow skills, engineering principles, task playbooks, specialized subagents, verification skills, and reflection/correction loops. The distinctive contribution is rigorous verification: proof by running the actual artifact, not by assertion, build success, or test count.

### Direct principles and mechanics

- Write less, higher quality; do not maximize lines of code.
- Skill-driven workflow: default entry point (`poteto-mode`), help, sharpening, architecture, arena, swarm, interrogation, verification, reflection, correction.
- Verification is first-class:
  - match verification to what changed: CLI runs the real command, UI walks the flow, migration replays real input, performance compares traces, storage reads the value back;
  - project-local verification skill with launch, doctor, drive, evidence, and cleanup;
  - feature map, one file per user-facing feature;
  - evidence must survive cleanup;
  - verification skill generation runs end to end before handoff.
- Blast radius: for a small-looking change, prove what else it could break using running code, not assertions.
- Architect: settle caller usage, types, and module shape before writing code that crosses a function boundary.
- Arena: N parallel attempts, then take the best parts.
- Swarm: N parallel workers across slices or races, then one aggregated report.
- Interrogate: different models try to break a diff; keep only findings a run proves.
- How/why: trace subsystem behavior and history using available evidence sources.
- TDD: for bugs with a cheap local test path, write the failing test first, then fix.
- No-comments: strip comments before review; spawn a reviewer; fix accepted findings; offer encodings for claimed constraints.
- Unslop: remove AI tells from writing.
- Technical writing: layered documentation standard.
- Reflect: capture a long task's recipe as a skill edit.
- Correct: mine repeated corrections, fix each at the highest level that works, and keep a rule-to-enforcement table.
- Model routing: `setup-pstack` detects available models and writes a config rule for per-role routing.
- Reproduce/fix/prove loops and verification maintenance playbooks.

### What we adopt, adapt, or reject

- Adopt: verification-first proof, evidence survival, blast-radius checks, architecture-before-code, reflect/correct loops, multi-model interrogation as an option.
- Adapt: our verify commands and task gates absorb verification-first; robust review absorbs interrogate; `retro` and `update` absorb reflect/correct; `modular-design` absorbs architect.
- Reject or avoid: plugin-specific model routing as a default; comment stripping as default; importing the full 23-skill suite; treating pstack's counts as stable facts.

### Coverage in our skill stack

- `implement`: verification and minimal changes.
- `review`: robustness and evidence-first findings.
- `retro`: session efficiency and actionable adjustments.
- `update`: reconciliation and loop closure.
- `author-skill`: overlap checks and reference discipline.
- `overlap-check`: prompt overlap audits.
- `nix-flake-eval`: flake verification hygiene.
- `upstream-recon`: evidence from store source.
- `modular-design`: architecture before code.

### Boundaries / things not to overattribute

- pstack is operational rigor and verification. It is not a direct overengineering checklist, deep-module framework, or simplicity ladder.
- Counts of skills, principles, playbooks, and subagents vary by version and secondary source; treat them as reported, not canonical.
- pstack's model routing and plugin mechanics are host-specific; our stack remains harness-neutral and Nix-owned.

## Cross-framework synthesis

- Ponytail supplies the code-minimization axis: YAGNI, reuse, dependency discipline, one-line preference, minimum code, safety preservation.
- Pocock supplies the module and workflow axis: deep modules, grilling, shared vocabulary, artifact chain, TDD, two-axis review, bug diagnosis.
- Osmani supplies the constraint and quality axis: quality bars, incremental slices, five-axis review, change sizing, Chesterton's Fence, Rule of 500, security/performance checklists, source-driven and doubt-driven review.
- pstack supplies the operational verification axis: evidence-first proof, blast radius, architecture before code, parallel review, reflect/correct.
- Our review model synthesizes these into profiles: diff, slice, and robustness, with always-on correctness, security, simplicity, traceability, and verification. Security and performance remain optional depth lenses; code simplification stays in the always-on simplicity check and `deslop`.
- Our RDST spine already provides the artifact chain that Pocock advocates; the gap is not a new artifact system but sharper use of existing artifacts.
- Simplicity is therefore one axis among several: module depth, constraint quality, and operational verification are separate and must be evaluated separately.

## Coverage matrix

| Source | Principle | Our coverage | Status |
|---|---|---|---|
| Ponytail | Lazy-senior ladder | `review` simplicity checks, `deslop` | adapted |
| Ponytail | YAGNI | `review`, `deslop`, `implement` | adopted |
| Ponytail | Reuse existing repo code | `implement`, `deslop` | adopted |
| Ponytail | Stdlib/native/installed dependency first | `implement`, `deslop`, `upstream-recon` | adopted |
| Ponytail | One line when possible | `review`, `deslop` | adapted |
| Ponytail | Minimum code | `review`, `deslop`, `implement` | adopted |
| Ponytail | No unrequested abstractions/deps/boilerplate | `review`, `deslop`, `modular-design` | adopted |
| Ponytail | Deletion over addition | `review`, `deslop` | adapted |
| Ponytail | Shortcut ceilings | no required tag; material limits belong in D/S if needed | deferred |
| Ponytail | Preserve validation/security/accessibility/errors | `deslop`, review security checks, rules | adopted |
| Ponytail | One runnable check for non-trivial logic | task verify commands, `implement` | adopted |
| Pocock | Grill with docs and shared language | `design` questions, `Qxx` | partial: no glossary artifact |
| Pocock | Deep modules | `modular-design` | adopted |
| Pocock | Architecture survey | `brainstorm`, `design`, `architecture.md` | partial: no periodic survey skill |
| Pocock | Small feedback steps | `implement`, task verify | adapted |
| Pocock | TDD red-green-refactor | `implement` test-first reference and red/green gate | adapted |
| Pocock | Bug diagnosis loop | not a default loop | missing |
| Pocock | to-spec synthesis | `specify` | adopted |
| Pocock | Tracer-bullet tickets | `plan`, `Txx` | adopted |
| Pocock | Two-axis review: standards + spec | `review` profiles and gates | adapted |
| Pocock | Remove no-op instructions | `overlap-check`, `author-skill` | adapted |
| Osmani | Constraint-driven quality bar | requirements, decisions, specs, verify | partial: no global constraints artifact |
| Osmani | Incremental vertical slices | `plan`, `implement`, review slice profile | adopted |
| Osmani | Change sizing (~100 lines) | atomic tasks, review caps | partial: no line-size metric |
| Osmani | Five-axis review | review always-on checks | adapted |
| Osmani | Code simplification | `deslop`, review simplicity | adopted |
| Osmani | Chesterton's Fence | `deslop` | adopted |
| Osmani | Rule of 500 | `deslop`, review | adopted |
| Osmani | Preserve behavior | `deslop`, review | adopted |
| Osmani | Security hardening checklist | optional `review/references/security.md` lens | adopted |
| Osmani | Performance checklist | optional `review/references/performance.md` lens | adopted |
| Osmani | Documentation and ADRs | `decisions.md`, `architecture.md` | adopted |
| Osmani | Source-driven development | `upstream-recon` | adopted |
| Osmani | Doubt-driven development | not a default implement step | missing |
| Osmani | Global definition of done | rejected; per-task verify and acceptance remain | rejected |
| pstack | Write less, higher quality | review, `deslop`, scope rules | adopted |
| pstack | Verification matching change type | task verify commands | adapted |
| pstack | Project-local verification skill | `nix-flake-eval` and task verify | partial |
| pstack | Evidence survives cleanup | review findings, artifacts | adapted |
| pstack | Reproduce/fix/prove | folded into `implement` test-first; no separate loop | adapted |
| pstack | Blast radius proof | not explicit | missing |
| pstack | Architect before code | `modular-design`, `design` | adopted |
| pstack | Arena/swarm parallelism | subagent caps and delegation rules | adapted |
| pstack | Multi-model interrogation | not adopted | rejected |
| pstack | Reflect/correct loops | `retro`, `update`, `overlap-check` | partial |
| pstack | Model routing policy | not adopted; harness-neutral metadata instead | rejected |
| pstack | No-comments/unslop | `deslop` | adapted |

## Decisions taken

- Adopt Osmani-style test-first in `implement`, using the failing test or failing eval as the red check.
- Adopt security and performance as optional review lenses, not always-on phases.
- Keep code simplification in the always-on simplicity checks and `deslop`.
- Reject a global definition of done; per-task verify and acceptance remain the gate.
- Reject multi-model interrogation and model routing; keep the harness-neutral review model.
- Reject a separate reproduce/fix/prove loop; reproduction is part of `implement` test-first.
- Defer shortcut-ceiling tagging. It is not a required convention. If a deliberate limit matters, record it in a decision or spec; do not add a `ponytail:` tag by default.

## Remaining candidates

1. Shared-language/glossary artifact for design and implementation, sourced from Pocock's grill-with-docs.
2. Project-local verification skill generation and maintenance, sourced from pstack, mapped to `nix-flake-eval` or `implement` references.
3. Reflect/correct automation for repeated corrections, sourced from pstack, mapped to `retro` and `update`.

All remain subordinate to the existing RDST spine and review profiles. None should become a micro-skill without a design decision.

## What shortcut ceilings mean

Ponytail's shortcut-ceiling rule asks the author to mark a deliberate simplification with its limit, such as an O(n²) scan that is safe for a known small input, so a future reader knows when to replace it. It is a communication device, not a verification gate. We defer it as a required convention; use an ordinary comment or a decision/spec when the limit is material.

## Simplicity is one axis

Simplicity is one axis, not the whole framework set. Ponytail's minimization ladder, deslop criteria, and the deletion test address code volume and speculative complexity. They do not cover module depth, quality constraints, TDD, security, performance, operational verification, or workflow rigor. Those are separate axes contributed by Pocock, Osmani, and pstack, and they must be evaluated and adopted on their own evidence.
