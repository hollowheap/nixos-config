# V01: AI Harnesses — Robustness Review

**User-visible outcome**: Declared AI agents, skills, rules, disciplines, hooks, and MCP servers render consistently and fail closed across all 9 Home Manager harnesses (`opencode`, `pi-coding-agent`, `claude-code`, `codex`, `kiro-cli`, `antigravity`, `github-copilot-cli`, `crush`, `hermes`).

### End-to-end verification command & observed results

```bash
# 1. Flake checks & HM activation package build (PASS)
nix build .#checks.x86_64-linux.skills .#checks.x86_64-linux.skills-rendered .#checks.x86_64-linux.ai-rendered --no-link
nix build .#homeConfigurations.hollowheap.activationPackage --no-link

# 2. Hook fail-closed verification on malformed input (FAIL - Kiro hook fails open)
printf '{"tool_input": malformed' | $(nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".kiro/hooks/prevent-overwrite.json"'.text | jq -r '.hooks[0].action.command')
# Observed: jq parse error; exit code 0

# 3. Requirement R23 verification check (FAIL - OMP module removed)
nix eval .#homeConfigurations.hollowheap.config.programs.omp.enable
# Observed: error: attribute 'omp' missing
```

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. `omp.nix` removed while `R23` remains `[x]` in `REQUIREMENTS.md`; `rulesText` duplicated with diverging subagent suppression between `home/lib/ai-render.nix:79` and `home/modules/ai/options.nix:582`. |
| architecture | loaded | `_module.args.aiRender` in `options.nix:510` wraps and shadows `home/lib/ai-render.nix`; `hermes.nix` writes `.hermes/config.yaml` without an `enable` toggle. |
| api | loaded | `ai.tiers.<tier>.efforts.kiro` carries inverted effort metadata unused by `kiro-cli.nix`; `programs.mcp.servers` is unmapped in Kiro, Antigravity, and Pi. |
| data | loaded | `lib/ai-skills.nix:134` flattens nested `scripts/` paths via `baseNameOf`; `parseAgents` splits comma-separated lists and misparses block YAML sequences. |
| security | loaded | **High**: `subagent-io.rules.read-only` injects read-only rule into read-write `worker`; `kiro-cli.nix:40-45` restricts architect to stale lowercase `.artifacts/{tasks,specs}.md`; `kiro-cli.nix:95` and `hooks.nix:81` fail open on malformed/empty JSON. |
| performance | loaded | `ai.hooks.pre-tool` omits a tool matcher, spawning `ai-git-policy` + multiple `jq` calls on non-bash tool calls across harnesses. |
| tests | loaded | `R23` verify command fails; `checkSkillsRendered` in `flake/default.nix:179` asserts Pi, Kiro, and Claude skill counts while leaving OpenCode, Codex, Antigravity, Crush, and Hermes unasserted. |
| ui | loaded | Wallust theme templates and Pi/Antigravity statuslines checked statically; live TUI/CLI visual rendering is **UNVERIFIED** (`ui-probe source .` reports `0` frontend files). |

---

## Failure modes

### 1. [High] Subagent `worker` injected with read-only discipline contradiction
- **Current**: [home/modules/ai/disciplines.nix:91-99](file:///home/hollowheap/repos/nixos-config/home/modules/ai/disciplines.nix#L91-L99), [home/modules/ai/agents.nix:110](file:///home/hollowheap/repos/nixos-config/home/modules/ai/agents.nix#L110)
- **Gap**: `subagent-io.rules.read-only` targets `target = "subagent"` with `"Subagents are strictly read-only; never mutate files, stage/commit, or expose secrets."`, yet `worker` is `role = "subagent"` with `capabilities = { write = true; execute = true; delegate = true; }`.
- **Failure/impact + repro**: Every rendered `worker` prompt tells the agent it is strictly read-only and never commits while simultaneously instructing it to implement tasks and commit linearly.
  ```bash
  nix eval --raw .#homeConfigurations.hollowheap --apply 'h: h.config.ai.render.agentBodyFor h.config.ai.agents.worker'
  ```
- **Config minimal shape**:
  ```nix
  # Option A: Gate subagent-io.rules.read-only on !agent.capabilities.write in options.nix
  # Option B: Reword rule to "Read-only subagents must never mutate files, stage/commit, or expose secrets."
  ```
- **Source**: Local `ai.*` contract (`home/modules/ai/disciplines.nix`, `home/modules/ai/agents.nix`).
- **Default check**: n/a.
- **Confidence**: Verified.

### 2. [High] Kiro architect write permissions deny `.artifacts/*.md` and still match deleted lowercase `tasks.md`/`specs.md`
- **Current**: [home/modules/programs/kiro-cli.nix:35-48](file:///home/hollowheap/repos/nixos-config/home/modules/programs/kiro-cli.nix#L35-L48), [home/modules/programs/opencode.nix:111](file:///home/hollowheap/repos/nixos-config/home/modules/programs/opencode.nix#L111)
- **Gap**: `kiro-cli.nix` restricts `architect` `fs_write` to `[ ".artifacts/tasks.md" ".artifacts/specs.md" ]` (both lowercase and incomplete), whereas `opencode.nix` allows `.artifacts/*.md` and `.artifacts/` files are now uppercase (`TASKS.md`, `SPECS.md`, `DECISIONS.md`, etc.).
- **Failure/impact + repro**: Under Kiro CLI, `architect` writes to `.artifacts/*.md` are blocked entirely by `fs_write` deny rules.
  ```bash
  nix eval --json .#homeConfigurations.hollowheap.config.home.file.'".kiro/agents/architect.json"'.text | jq -r '.toolsSettings'
  ```
- **Config minimal shape**:
  ```nix
  exclude = [ ".artifacts/*.md" ".artifacts/**/*.md" ];
  match = [ ".artifacts/*.md" ".artifacts/**/*.md" ];
  ```
- **Source**: [.artifacts/REQUIREMENTS.md:193](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md#L193) (`R27`).
- **Default check**: Kiro `fs_write` rules default to explicit allow/deny rules.
- **Confidence**: Verified.

### 3. [Medium] Kiro `prevent-overwrite.sh` hook fails open on malformed JSON
- **Current**: [home/modules/programs/kiro-cli.nix:95-104](file:///home/hollowheap/repos/nixos-config/home/modules/programs/kiro-cli.nix#L95-L104)
- **Gap**: `preventOverwriteHook` uses `pkgs.writeShellScript` without `set -euo pipefail`. On invalid JSON, `jq` fails without aborting the script (`exit 0`).
- **Failure/impact + repro**: Malformed pre-tool payloads fail open instead of blocking per `R30`.
  ```bash
  printf '{"tool_input": malformed' | $(nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".kiro/hooks/prevent-overwrite.json"'.text | jq -r '.hooks[0].action.command'); echo "Exit: $?"
  ```
- **Config minimal shape**: Build with `pkgs.writeShellApplication` (`set -euo pipefail`) so `jq` parse failures exit nonzero.
- **Source**: [.artifacts/REQUIREMENTS.md:214](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md#L214) (`R30`).
- **Default check**: `writeShellScript` omits `-euo pipefail`.
- **Confidence**: Verified.

### 4. [Medium] `ai-git-policy` exits `0` on empty stdin payload
- **Current**: [home/modules/ai/hooks.nix:81-87](file:///home/hollowheap/repos/nixos-config/home/modules/ai/hooks.nix#L81-L87)
- **Gap**: When stdin is empty (`""`), `jq -r` succeeds cleanly with empty `tool`, falling through to `*) exit 0 ;;`.
- **Failure/impact + repro**: Closed/empty stdin hook invocations pass unblocked.
  ```bash
  printf '' | $(nix eval --raw .#homeConfigurations.hollowheap.config.ai.hooks.pre-tool.command); echo "Exit: $?"
  ```
- **Config minimal shape**: Reject empty input with `[ -n "$input" ] || { echo "Empty payload rejected" >&2; exit 2; }`.
- **Source**: [.artifacts/REQUIREMENTS.md:214](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md#L214) (`R30`).
- **Default check**: `jq` on empty input returns empty/exit 0.
- **Confidence**: Verified.

### 5. [Medium] MCP server registry parity gap across harnesses
- **Current**: [home/modules/programs/kiro-cli.nix:125](file:///home/hollowheap/repos/nixos-config/home/modules/programs/kiro-cli.nix#L125), [home/modules/programs/pi-coding-agent.nix:292](file:///home/hollowheap/repos/nixos-config/home/modules/programs/pi-coding-agent.nix#L292), [home/modules/programs/antigravity.nix](file:///home/hollowheap/repos/nixos-config/home/modules/programs/antigravity.nix)
- **Gap**: `programs.mcp.servers` renders for OpenCode, Claude Code, Codex, Crush, and Copilot, while Kiro sets `includeMcpJson = caps.mcp` without generating `~/.kiro/settings/mcp.json`, Pi disables `-builtin:mcp`, and Antigravity has no mapping.
- **Failure/impact + repro**: Adding an MCP server silently omits it in Kiro, Pi, and Antigravity.
- **Config minimal shape**: Either wire `.kiro/settings/mcp.json` and supported adapters or explicitly document non-supporting harnesses under `R29`.
- **Source**: [.artifacts/REQUIREMENTS.md:207](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md#L207) (`R29`).
- **Default check**: n/a.
- **Confidence**: Verified.

### 6. [Low] `pre-tool` hook omits tool matcher, spawning `ai-git-policy` + `jq` on every tool call
- **Current**: [home/modules/ai/hooks.nix:133-138](file:///home/hollowheap/repos/nixos-config/home/modules/ai/hooks.nix#L133-L138)
- **Gap**: Unlike `post-tool`, `pre-tool` declares no per-harness shell-tool matcher.
- **Failure/impact + repro**: Every read, grep, or delegate tool call incurs a subshell + `jq` invocation before exiting `0`.
- **Config minimal shape**: Add per-harness shell matchers on `ai.hooks.pre-tool` matching `post-tool`'s pattern (`hooks.nix:148-155`).
- **Source**: Local hook framework (`home/modules/ai/hooks.nix`).
- **Default check**: None.
- **Confidence**: Verified.

### 7. [Low] `lib/ai-skills.nix` `parseAgents` ignores block YAML lists and `readTextFiles` flattens nested `scripts/`
- **Current**: [lib/ai-skills.nix:134,160-165](file:///home/hollowheap/repos/nixos-config/lib/ai-skills.nix#L134)
- **Gap**: `parseAgents` only splits inline comma lists, and `readTextFiles` uses `baseNameOf` instead of preserving relative subpaths like `readReferenceFiles`.
- **Failure/impact + repro**: Skills authored with `- agent` YAML sequences or nested `scripts/sub/foo.sh` paths lose agent scoping or collide on basename.
- **Config minimal shape**: Normalize block YAML list items in `parseAgents` and use `lib.removePrefix` in `readTextFiles`.
- **Source**: Local skill loader (`lib/ai-skills.nix`).
- **Default check**: n/a.
- **Confidence**: Verified.

---

## Seams

1. **Duplicate `rulesText`**: [home/lib/ai-render.nix:79-84](file:///home/hollowheap/repos/nixos-config/home/lib/ai-render.nix#L79-L84) is shadowed by `_module.args.aiRender` in [home/modules/ai/options.nix:510,582-588](file:///home/hollowheap/repos/nixos-config/home/modules/ai/options.nix#L582-L588), which adds subagent rule suppression.
2. **Script vs. Reference path preservation**: `lib/ai-skills.nix:134` flattens `scripts/` via `baseNameOf`, whereas `lib/ai-skills.nix:144` preserves subdirectories in `references/`.
3. **Unmanaged `hermes.nix`**: [home/modules/programs/hermes.nix](file:///home/hollowheap/repos/nixos-config/home/modules/programs/hermes.nix) lacks an `enable` toggle and unconditionally generates `.hermes/config.yaml`.
4. **Hardcoded agent permission branches**: `opencode.nix` and `kiro-cli.nix` special-case `scout`, `worker`, `architect`, and `ask` names alongside capability flags.

---

## Rejected defaults

- OpenCode permissive default permission → overridden with explicit `*: deny` first.
- Pi `enableInstallTelemetry = true` → overridden to `false`.
- Claude Code telemetry/auto-updater → disabled via `DISABLE_TELEMETRY`, `DISABLE_ERROR_REPORTING`, `DISABLE_AUTOUPDATER`.
- Codex deprecated `features.codex_hooks` → replaced with `features.hooks = true`.

---

## Blocking Design Forks

1. **Subagent capability contract vs. `subagent-io` read-only discipline** → route to `/design` (`home/modules/ai/disciplines.nix:98` vs. `worker` `write = true`).
2. **Requirement `R23` (`omp`) disposition** → route to `/design` (`R23` marked `[x]` in `REQUIREMENTS.md:165` while `home/modules/programs/omp.nix` was removed).
