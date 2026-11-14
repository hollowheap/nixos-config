# Multi-Session Corpus Audit

Use when sweeping compacted logs and transcripts across past sessions before tuning harness rules, agent definitions, skills, or `AGENTS.md`.

## Checks

- **Systemic blind spots:** places where agents repeatedly ignored core repo stack facts, ran wrong tools, or missed existing helpers.
- **Cross-session loops & cognitive traps:** recurring confirmation bias, hypothesis thrashing, or rationalized command failures across sessions.
- **Knowledge amnesia & user friction:** repo facts re-discovered across isolated sessions that belong in `AGENTS.md`, or recurring user config/prompt mistakes causing failed runs.
- **Rule & discipline effectiveness:** quantify repeated searches, oversized dumps, ineffective subagent spawns, and which rules or disciplines were ignored, redundant, or contradictory.

## Report Template (`audit.md` or inline)

Cite session IDs and step counts per finding, propose systemic changes rather than one-off patches, and keep any Markdown tables `<= 80` characters wide:

```markdown
# Corpus Audit: <scope>

## Systemic Blind Spots

- **<Pattern>** (<session-ids>, <N> steps): <what agents missed>.

## Cross-Session Loops & User Friction

- **<Loop/friction>** (<session-ids>): <recurring cause>.

## Rule Effectiveness & Systemic Fixes

- **<Ignored or redundant rule>** -> **<Target file/config>**: <concrete systemic edit>.
```
