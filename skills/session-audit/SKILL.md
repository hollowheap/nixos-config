## Workflow

1. Locate transcript JSONL log in `.system_generated/logs/transcript.jsonl` or path specified by user.
2. Run audit parser or inspect tool sequences to detect repeated tool calls, consecutive failures, and stall sequences.
3. Inspect flagged steps to classify loop patterns:
   - **Command thrashing**: Identical command retried after failure without parameter changes.
   - **File ping-pong**: Repeatedly reading or editing the same file without forward progress.
   - **Hypothesis oscillation**: Flipping between two explanations without isolating discriminating variables.
   - **Premature closure**: Claiming task complete without executing verification command.
4. Synthesize high-density diagnosis: Loop Class -> Step Indices -> Root Cause -> Rule / Discipline Remedy.
5. Propose specific prompt or rule adjustments to eliminate recurrence.

## Rules

- Base audit strictly on verbatim transcript log lines, never on agent self-reports.
- Quantify stall cost: cite exact step indices and wasted tool invocation count.
- Classify each loop into a formal failure category.
- Verify: Audit cites exact step numbers and proposes concrete rule or discipline changes.
