# Harness & Prompt Doctor

Use when troubleshooting broken harness setups, user misconfigurations, slow hooks, auth failures, MCP overhead, or bloated instruction/skill contexts.

## Checks

- **Installation & binaries:** confirm active binary paths (`which`, symlinks) and flag stale, shadowed, or conflicting user installs.
- **Settings & user mistakes:** inspect live harness configs (`~/.claude/`, `~/.codex/`, `~/.gemini/antigravity-cli/`, `~/.pi/`, `~/.kiro/`, `~/.config/opencode/`) and any repo-local overrides for invalid JSON/TOML, unknown keys, conflicting permissions, broken file paths, or unsupported model IDs.
- **API keys & auth:** verify required provider env vars and credential helpers resolve cleanly in the active shell without silent failures or expired tokens.
- **Hooks & permissions:** check hook scripts, executable bits, matchers, timeouts, and harness flags for syntax errors, missing binaries, or overly broad blocks.
- **Prompt & MCP bloat (`/doctor prompt-audit`):** measure system/agent/skill/discipline prompt sizes (`chars/4` tokens), `AGENTS.md` and context file line counts, unused or auto-loaded skills, and active MCP tool schema overhead.

## Report Template

Keep reports concise and keep any Markdown tables `<= 80` characters wide:

```markdown
# Harness Doctor Report

## Summary

- Scope audited and overall health status.

## Findings

- **<Component>** (`<file:line>`): <problem or user misconfiguration>. Fix: <concrete change>.

## Verification

- `<exact command>` -> `<observed result>`
```

## Verify

Re-run the failing harness command, hook check, or repository build/eval target (if declaratively managed) and confirm both correctness and reduced prompt or MCP token overhead.
