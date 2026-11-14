# Single-Session Retro, Tokens & Model Fit

Use when auditing one session for wasted turns, token bloat, wrong model-tier selection, user-prompt friction, or execution loops.

## Checks

- **Tool efficiency & errors:** count total steps, tool calls, and failed commands; flag repeated searches or subagent latency.
- **Loop classification:**
  - `Command thrashing`: identical command retried after failure without changing parameters.
  - `File ping-pong`: reading or editing the same file repeatedly without forward progress.
  - `Hypothesis oscillation`: alternating between explanations without a discriminating test.
  - `Premature closure`: claiming completion without running the verification command.
- **Context & token waste (`/context`, `/usage`):** flag unpiped command dumps, full-file reads over targeted slices, heavy skill/MCP preloads, and unnecessary subagent spawns.
- **Model, effort & user fit (`/model`):** compare task complexity against configured model tiers and agent roles. Flag overkill (`high` reasoning spent on mechanical edits), underpowering (`low` tiers thrashing), and ambiguous or over-constrained user setup/instructions that caused rework.
- **Winning patterns:** note fast `rg` lookups, batched reads, minimal diffs, and tight red-to-green verification loops to preserve.

## Report Template (`retro.md` or inline)

Keep reports brief and keep any Markdown tables `<= 80` characters wide:

```markdown
# Session Retro: <session-id>

## Tool Efficiency & Loops

- Steps: <N> | Failed calls: <N> | Wasted turns: <N>
- **<Loop type>** (steps <x-y>): <verbatim cause>.

## Token & Model Fit

- Prompt/tool bloat: <source> (~<N> tokens).
- Model/user fit: <tier or instruction mismatch>.

## Winning Patterns

- <Pattern worth keeping>.

## Actionable Fixes

- **<Target file/config>**: <concrete edit>.
```
