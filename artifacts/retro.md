# Session Retrospective: Skill Architecture, Hook Modularization, and Prompt Density

## 1. Tool Efficiency & Errors

### Metric Summary
- **Total Session Steps**: ~1026 steps recorded in `transcript.jsonl`.
- **Tool Call Breakdown**:
  - `view_file`: 195 calls (dominant read mechanism).
  - `run_command`: 133 calls (builds, checks, eval, process inspection).
  - `replace_file_content`: 64 calls (surgical line replacements).
  - `manage_task`: 22 calls (asynchronous build monitoring).
  - `search_web`: 10 calls (external documentation lookup).
  - `invoke_subagent`: 5 calls (Scout, Researcher, Architect).
  - `write_to_file`: 3 calls (creating new modules).
- **Error Incidents**:
  - Stale `.git/index.lock` blocking `git add -N`: Diagnosed and cleared via `rm .git/index.lock`.
  - Slice line mismatch on `replace_file_content`: Fixed by inspecting exact target line bounds before editing.
  - Python3 missing from PATH: Adapted immediately to native `jq` shell commands.

### Friction Points
- **Uncritical Prompt Mirroring**: When given a prompt with a caveat ("not sure if this overlaps with anything with author-harness"), the agent implemented `author-hook` directly as a Pi-specific JSON writer instead of scouting repository hook plumbing (`pkgs/ai-hooks.nix`, `home/modules/ai/hooks.nix`).
- **Redundant Tool Poll Prevention**: Asynchronous background builds (`manage_task`) were initiated correctly, but waiting turns occasionally required explicit wake-up notifications.

---

## 2. Rule Compliance

| Rule / Discipline | Compliance | Findings |
| :--- | :--- | :--- |
| **`lazy` (YAGNI)** | Mixed | Refactored Neovim cleanly and compressed prompt disciplines; but authored `author-hook` prematurely as an isolated micro-skill. |
| **`unslop`** | High | Answers maintained <=20 words/sentence, dropped unnecessary articles, and kept technical payloads verbatim. |
| **`report` Formula** | High | Turns concluded with verbatim `Done: ... / Verified: ... / Next: ...` without prose recaps. |
| **`skills` & `grill`** | High | Batched reconnaissance before asking questions; avoided speculative skill reloads. |
| **Flake Eval Hygiene** | High | Staged untracked files with `git add -N` before running Nix builds. |

---

## 3. Winning Patterns

1. **Domain Co-location over Monolithic Lists**:
   - Extracting `quickfix.nix`, `preview.nix`, and `editing.nix` out of monolithic `keymaps.nix` and `core.nix` eliminated orphan keymaps while keeping Home Manager builds green.
2. **Lean Skill Template Extraction**:
   - Keeping `## Workflow` strictly to 3–5 procedural steps and moving schemas/templates into `references."examples.md"` dramatically reduced prompt token load.
3. **Cognitive Stance + Operational Clamping**:
   - Replacing verbose prose disciplines with technical role archetypes and rigid negative invariants preserved high semantic density while cutting token waste by ~40%.
4. **Effective Subagent Specialization**:
   - Spawning `architect` for cognitive prompt testing and `researcher` for external stack comparisons kept the parent context clean and focused.

---

## 4. Root Cause Analysis: The `author-hook` Anti-Pattern

### The Flaw
The user asked to author `author-hook` for Pi lifecycle hooks, explicitly questioning overlap with `author-harness`. The agent implemented a standalone, Pi-specific skill (`.pi/hooks.json` writer) one-to-one without checking repo context.

### Why This Was Broken
1. **Repository Invariant Breach**:
   - In `nixos-config`, Pi hooks are **not** managed by hand-editing `~/.pi/agent/hooks.json`.
   - They are generated declaratively via Home Manager (`home/modules/programs/pi-coding-agent.nix`) from `config.ai.hooks`.
   - Ad-hoc editing of `~/.pi/agent/hooks.json` will be clobbered or produce collision errors during `home-manager switch`.
2. **Polymorphic Architecture Violation**:
   - Hook behavior is centralized across all 8 harnesses via `pkgs/ai-hooks.nix` (`session-start`, `pre-tool`).
   - Introducing a Pi-only skill breaks the repository's harness-agnostic abstraction.
3. **`author-skill` Invariant Violation**:
   - Rule 2 of `author-skill`: *"Check for overlap against existing skills; fold micro-rules into conventions or parent skills instead of creating single-command skills."*
   - The capability belongs in `author-harness` (for mapping harness hooks) and `pkgs/ai-hooks.nix` (for implementing hook logic), not in a standalone micro-skill.

---

## 5. Actionable Improvements

1. **Revert / Clean Up `author-hook`**:
   - Remove the Pi-specific `author-hook` micro-skill from `home/modules/ai/skills.nix` and `home/modules/ai/agents.nix`.
   - Document Pi hook contracts directly in `pkgs/ai-hooks.nix` and `home/modules/programs/pi-coding-agent.nix` where Home Manager renders them.
2. **Update `author-skill` Invariant**:
   - Add explicit rule: *"Never author a harness-specific micro-skill when the repository manages that capability polymorphically across harnesses (e.g. `ai.hooks`, `ai.render`)."*
3. **Update Recon Discipline**:
   - Add invariant: *"When user questions overlap or proposes a harness-specific tool, inspect existing shared packages (`pkgs/`) and modules (`home/modules/ai/`) before authoring."*
