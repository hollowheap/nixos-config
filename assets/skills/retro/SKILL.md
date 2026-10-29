## Workflow

1. Inspect active conversation context and the verbatim transcript log; resolve the active harness store instead of assuming one path.
2. Audit tool efficiency and errors: quantify total steps, tool call counts, and command failure rate; flag command thrashing, repetitive searches, or excessive subagent latency.
3. Extract winning patterns: identify fast symbol lookups, direct minimal edits, and tight verification loops.
4. Synthesize durable improvements into `artifacts/retro.md`: propose concrete prompt or tool adjustments, never hardcode another harness's path; propose convention updates in `AGENTS.md` for undocumented project behaviors.

## Rules

- Never trigger or preload retro automatically; run only on an explicit retro request.
- Base retrospective strictly on verbatim session evidence, never on speculative self-reports.
- Focus on execution efficiency and winning habits; do not reconcile artifacts here.
- Every identified friction point must produce a concrete, actionable prompt, tool, or doc adjustment.
- Verify: `artifacts/retro.md` contains Tool Efficiency & Errors, Winning Patterns, and Actionable Improvements.
