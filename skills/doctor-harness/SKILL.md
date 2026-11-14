---
name: doctor-harness
description: Diagnose harness misconfigurations, user setup errors, prompt/MCP bloat, single-session loops/model fit, or multi-session friction across any repository.
disable-model-invocation: true
agents: architect, engineer
---

# Doctor Harness

## Workflow

1. Route by request: load `references/doctor.md` for harness setup, user misconfigurations, hooks, MCPs, or prompt bloat; `references/session.md` for one transcript's loops, tokens, or model-tier fit; or `references/corpus.md` for multi-session patterns, then resume at step 2.
2. For `session` or `corpus` mode, query the target harness store read-only via `references/ingestion.md`, then resume at step 3.
3. Inspect verbatim logs, live harness settings, workspace instruction files (`AGENTS.md`, `CLAUDE.md`, rules), or declarative config files when present; never rely on agent self-reports.
4. Quantify evidence with exact step indices, session IDs, wasted tool counts, `chars/4` token estimates, or failing config lines, including user-caused misconfigurations.
5. Propose concrete fixes to user harness settings, hooks, MCPs, `AGENTS.md`, or declarative AI config modules (if used by the repo); wait for confirmation before editing.
6. Report findings inline, or write `retro.md` (`session`) or `audit.md` (`corpus`) into `artifacts/` when present and requested, or verify repaired config (`doctor`).

## Rules

- Run only on explicit request; never preload or auto-trigger.
- Never mutate a session store or fabricate missing transcript logs; redact secrets and tokens from reports.
- Load only the single matching mode reference (`doctor`, `session`, or `corpus`) and load `references/ingestion.md` only when reading logs; never read other mode references.
- Cite verbatim evidence (`file:line`, step index, or session ID) and one concrete remedy for every finding.
- Verify: output cites exact evidence and the repaired config, hook check, or repo build passes.
