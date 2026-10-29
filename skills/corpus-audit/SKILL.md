## Workflow

1. Ingest compacted session logs and transcripts across past runs; see `references/ingestion.md` for every harness store and query.
2. Audit systemic workspace blind spots: flag where agents ignored core repo stack facts, ran the wrong package manager, or overlooked existing wrappers.
3. Audit thinking loop patterns and cognitive traps: confirmation bias, hypothesis thrashing, or rationalizing failed commands.
4. Detect knowledge amnesia: facts re-discovered across isolated sessions that belong in `AGENTS.md` or repo context.
5. Quantify tool and prompt waste, and discipline effectiveness: repeated searches, oversized dumps, ineffective subagent spawns, and which active disciplines or rules were ignored. Propose adjustments to the discipline or rule list, not session-local rules.
6. Synthesize findings into `artifacts/audit.md` with concrete harness rule and prompt changes for `author-harness`.

## Rules

- Run only on an explicit request for a multi-session audit, or when preparing harness improvements with `author-harness`.
- Base findings on cross-session verbatim transcript evidence with cited session IDs and step counts.
- Prioritize systemic root causes over single-session typos.
- Verify: `artifacts/audit.md` exists with cited session IDs, blind spots, loop patterns, knowledge amnesia, and actionable harness improvements.
