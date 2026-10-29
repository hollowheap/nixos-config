# AI harnesses robustness review

## Verdict
- Biggest risk: OpenCode permission blocks put `"*": "deny"` last, but OpenCode resolves the last matching rule; architect, scout, worker, and ask lose edit, bash, and delegation. The known child-session tool stripping is this ordering bug, not missing agent definitions (`home/modules/programs/opencode.nix:71-126`).
- Biggest missing option: one `programs.mcp.servers` registry wired into every renderer. `capabilities.mcp` exists, but no harness writes a server; only Copilot flips `enableMcpIntegration` against an empty registry (`github-copilot-cli.nix:68`).
- Seam worth changing: six harnesses render `agent.instructions` (default `""`) while only OpenCode renders `agent.prompt`; route all through `aiRender.agentBodyFor` and one model table.

## Findings

### F1: OpenCode permission rules are inverted and `write` is not a permission key
- Current: `home/modules/programs/opencode.nix:98-113` emits `artifacts/*.md: allow` then `"*": "deny"` under `edit`, `write`, and `bash`; `:71-83` does the same for scout; `:84-92`, `:114-119` do it for `task`.
- Gap: OpenCode evaluates permission rules in order and **last match wins**; docs tell you to put `"*"` first, specifics after. `write` is not a key; `edit` covers `write`/`edit`/`patch`.
- Failure/impact: architect and scout deny every edit and command, so OpenCode hides `edit`/`write` while `bash` stays listed; all three primaries deny every subagent, so `task` never spawns. Child architect sessions therefore have no write/edit despite `tools.write = true`.
- Config:
```nix
# each block: deny catch-all first, then allows; delete the write: block
permission:
  edit: { "*": "deny", "artifacts/*.md": "allow" }
  task: { "*": "deny", scout: "allow", researcher: "allow" }
```
- Source: https://opencode.ai/docs/permissions/#granular-rules-object-syntax, https://opencode.ai/docs/agents/#task-permissions
- Default check: no; OpenCode defaults permissive, deny ordering is user-owned.
- Confidence: verified

### F2: Agent prompts render empty in seven of nine harnesses
- Current: `home/modules/ai/options.nix:157` defaults `instructions = ""`; `home/modules/ai/agents.nix` sets only `prompt`. Renderers interpolate `agent.instructions`: `pi-coding-agent.nix:38`, `omp.nix:36`, `codex.nix:78`, `kiro-cli.nix:174`, `antigravity.nix:71`, `github-copilot-cli.nix:40`, `crush.nix:19`.
- Gap: only `opencode.nix:140` calls `aiRender.agentBodyFor`, which prefers `prompt` and appends disciplines (`options.nix:515-535`). Every other harness ships an empty role body.
- Failure/impact: all non-OpenCode agents run without their role brief; `ask`'s `dropDisciplines`, subagent-io discipline, and capability-gated rules never reach them; behavior differs by harness.
- Config:
```nix
${aiRender.agentBodyFor "pi" agent}   # replace agent.instructions in each renderer
```
- Source: https://github.com/nix-community/home-manager/blob/master/modules/programs/pi-coding-agent.nix
- Default check: no.
- Confidence: verified

### F3: OpenCode plugin never loads; hooks are inert
- Current: `home/modules/programs/opencode-ai-hooks.ts:1` imports `@opencode/plugin`; `:36` calls `Plugin.define`; `:42` uses `ctx.event.subscribe`; `:48` uses `ctx.tool.hook("execute.before")`; `:49-53` reads `event.tool`/`event.input`.
- Gap: documented API is `import type { Plugin } from "@opencode-ai/plugin"`, default export `async (ctx) => ({ "tool.execute.before": (input, output) => ... })`; command is `output.args.command`; lifecycle events use the `event` hook.
- Failure/impact: module resolution fails, so session-start repomap and pre-tool guard never run in OpenCode; even with the import fixed, the hook receives no command and exits 0.
- Config: rewrite per plugin docs; register `event` for `session.created`/`session.idle`.
- Source: https://opencode.ai/docs/plugins/#basic-structure
- Default check: no; docs prescribe the shape.
- Confidence: verified

### F4: Pi and OMP `hooks.json` and `statusline.json` are not config surfaces
- Current: `pi-coding-agent.nix:189` writes `~/.pi/agent/hooks.json`; `omp.nix:72` writes `.omp/agent/hooks.json`; `omp.nix:169-177` writes `statusline.json`.
- Gap: Pi hooks are TypeScript extensions registered with `pi.on(...)`; Pi settings expose no hooks file. OMP discovers `.omp/agent/hooks/{pre,post}/*.ts|js` and reads `statusLine` from `config.yml`.
- Failure/impact: both hook files are dead; OMP statusline is dead; neither harness gets a pre-tool guard or repomap session start.
- Config:
```nix
# OMP: settings.statusLine.preset = "default";
# Pi/OMP: ship an extension under hooks/pre/*.ts calling pi.exec(), or delete the files
```
- Source: https://pi.dev/docs/latest/extensions, https://github.com/can1357/oh-my-pi/blob/main/docs/hooks.md, https://github.com/can1357/oh-my-pi/blob/main/docs/settings.md
- Default check: no.
- Confidence: verified against docs; runtime not executed.

### F5: Hook protocol leaks: `command` ignored, matchers divergent, pre-tool fails open
- Current: `pi-coding-agent.nix:203-208` and `omp.nix:86-91` hardcode `${pkgs.ai-hooks}/bin/ai-hooks` and ignore `config.ai.hooks.<name>.command`; `hermes.nix:39-56` ignores `harnesses` and `matcher`; `crush.nix:89-94` hardcodes `^bash$`; `pkgs/ai-hooks.nix:42-47` exits 0 when jq finds no command.
- Gap: `options.nix:326-334` promises `command`, `matcher`, `harnesses`; renderers reimplement the contract inconsistently.
- Failure/impact: replacing the hook command affects only some harnesses; non-bash guards never fire; malformed payloads pass silently, so guards are advisory, not enforcement.
- Config: render `hook.command` plus `--harness`, pass `hook.matcher` verbatim, and fail closed on parse error for pre-tool.
- Source: https://github.com/charmbracelet/crush/blob/main/docs/hooks/README.md
- Default check: no.
- Confidence: verified

### F6: Crush model settings are not in the schema
- Current: `home/modules/programs/crush.nix:40-42` sets top-level `default_provider`, `default_model`, `reasoning_effort`.
- Gap: Crush config top level is `models`, `providers`, `mcp`, `lsp`, `options`, `permissions`, `tools`, `hooks`, `env`; routing lives in `models.<role> = { provider, model, reasoning_effort }`.
- Failure/impact: all three keys are ignored, so Crush runs the built-in Catwalk default instead of `opencode-go`; cost and behavior diverge from every other harness.
- Config:
```nix
settings.models.large = { provider = "opencode-go"; model = "deepseek-v4.1-flash"; reasoning_effort = "high"; };
settings.models.small = { provider = "opencode-go"; model = "beam-free"; };
```
- Source: https://charm.land/crush.json
- Default check: no; Crush's own default provider wins.
- Confidence: verified

### F7: `capabilities.mcp` is inert; no MCP registry exists
- Current: `options.nix:110-114` defines the capability; OpenCode `toolsFor` never maps it (`opencode.nix:12-27`); Pi disables `builtin:mcp` (`pi-coding-agent.nix:336`); Kiro only sets `includeMcpJson` (`kiro-cli.nix:177`); Copilot enables integration with no servers (`github-copilot-cli.nix:68`).
- Gap: Home Manager ships `programs.mcp.servers` plus per-app `enableMcpIntegration` for OpenCode, Codex, Crush, and Copilot; the repo uses none.
- Failure/impact: `mcp = true` yields no tools anywhere; Kiro reads a `~/.kiro/settings/mcp.json` that never exists; agents that need MCP silently underperform.
- Config:
```nix
programs.mcp.enable = true;
programs.mcp.servers.context7 = { url = "https://mcp.context7.com/mcp"; };
programs.opencode.enableMcpIntegration = true;  # + codex, crush, copilot
```
- Source: https://github.com/nix-community/home-manager/blob/master/modules/programs/mcp.nix
- Default check: no; integration is opt-in.
- Confidence: verified

### F8: Kiro skills lack frontmatter; `effort` is not an agent field
- Current: `home/modules/programs/kiro-cli.nix:31-39` writes `# name` + description with no YAML; `:179` sets `effort`; `:162` uses `skill://.kiro/skills/<name>/SKILL.md`.
- Gap: Kiro follows agentskills.io and requires `name`/`description` frontmatter; the agent schema has no `effort` (effort is `/effort` or `--effort`); resources take `skill://<name>`.
- Failure/impact: skills fail discovery, `effort` is ignored or the config is rejected, and `skill://` paths may not resolve; `claude-haiku-5.5` also overrides tier policy.
- Config: reuse `aiRender.mkSkillDir`; `resources = [ "skill://${name}" ]`; drop `effort`.
- Source: https://kiro.dev/docs/custom-agents/configuration-reference, https://kiro.dev/docs/skills, https://kiro.dev/docs/models/effort
- Default check: no.
- Confidence: verified for fields; UNVERIFIED for runtime rejection behavior.

### F9: Codex hooks need a feature flag; agent `worker` collides with built-in
- Current: `home/modules/programs/codex.nix:95-101` omits `features.hooks`; `:104-108` writes `hooks.json`; `:74-81` writes `agents/worker.toml`.
- Gap: Codex loads `hooks.json` only with `features.hooks = true` (deprecated alias `features.codex_hooks`); Codex ships built-in `default`, `worker`, and `explorer` agents.
- Failure/impact: the pre-tool guard never runs; a custom `worker` either shadows or conflicts with the built-in role; hardcoded `gpt-6-luna`/`xhigh` bypasses `ai.tiers`.
- Config:
```nix
settings.features.hooks = true;
# rename agents/worker.toml -> agents/task-worker.toml
```
- Source: https://developers.openai.com/codex/config-reference, https://developers.openai.com/codex/multi-agent
- Default check: no; hooks are gated.
- Confidence: verified for the gate; UNVERIFIED whether the custom worker shadows or errors.

### F10: Model and effort routing is not one table
- Current: `options.nix:485-499` resolves only `opencode`, `pi`, `omp`; Codex hardcodes `codex.nix:79-80`; Kiro maps tier at `kiro-cli.nix:141-153`; Antigravity hardcodes `model: flash` at `antigravity.nix:54`; Crush keys are invalid at `crush.nix:40-42`; OpenCode duplicates the medium model at `opencode.nix:29`.
- Gap: `ai.tiers` is documented as the routing table (`options.nix:308`) but four harnesses ignore it; the effort enum stops at `high` while Pi, Kiro, and Codex accept `xhigh`/`max`.
- Failure/impact: changing a tier moves two harnesses only; model deprecation needs edits in five files; cost and quality diverge per harness.
- Config: add per-harness branches to `modelFor`/`effortFor`, or default `models.<harness>` from the tier.
- Source: local.
- Default check: n/a.
- Confidence: verified

### F11: API-key bootstrap misses OMP, Hermes, Antigravity, Copilot
- Current: `home/modules/terminal/zsh.nix:299-307` matches `opencode*|pi*|crush*|kiro*|codex*`; OpenCode uses only provider env (`opencode.nix:155-163`); Pi and OMP embed `!rbw get` in `auth.json` (`pi-coding-agent.nix:267-283`, `omp.nix:120-136`); no harness preflights the key.
- Gap: OMP, Hermes, Antigravity, and Copilot never trigger `_load_ai_keys`; `rbw` lock errors are swallowed.
- Failure/impact: first request returns 401; a stale `OPENCODE_API_KEY` is never refreshed; Hermes and Copilot auth paths differ entirely.
- Config:
```nix
case "$1" in opencode*|pi*|omp*|hermes*|crush*|kiro*|codex*|agy*|antigravity*|copilot*) _load_ai_keys ;; esac
```
- Source: local.
- Default check: no.
- Confidence: verified

### F12: No cost, fallback, telemetry, session-export, or local-model policy
- Current: no `programs.mcp`; Pi disables `builtin:llama.cpp` (`pi-coding-agent.nix:338`); Pi `budgets` is a statusline component only (`:63-65`); no `compaction`, `steps`, `enabledModels`, or `retry` settings; Pi `enableInstallTelemetry` defaults true; Copilot `autoUpdate` defaults true.
- Gap: no shared budget cap, provider fallback, rate-limit policy, telemetry opt-out, session export, or local model registry.
- Failure/impact: a `beam-free` quota or provider outage halts every primary; long sessions can compact away RDST state; install telemetry stays on; no cross-harness usage view.
- Config:
```nix
programs.pi-coding-agent.settings.enableInstallTelemetry = false;
programs.opencode.settings.compaction.reserved = 20000;
programs.opencode.validateFiles.config = true;   # catches unknown keys like permission.write
```
- Source: https://pi.dev/docs/latest/settings, https://opencode.ai/docs/config/#compaction
- Default check: yes for compaction/retry; the opt-outs and caps are absent.
- Confidence: verified

## Harness matrix
- opencode -> `opencode.json`, `cli.json`, `agents/*.md`, `skills/*`, `ai-hooks.json`, `plugins/ai-hooks.ts` -> inverted permissions, dead plugin, no MCP, deprecated `tools`.
- pi -> `settings.json`, `agents/*.md`, `skills/*`, `hooks.json`, `statusline.json`, `dashboard.json`, `auth.json`, `web.json` -> dead hooks/statusline, empty prompts, unpinned git package.
- codex -> `config.toml`, `agents/*.toml`, `hooks.json`, `skills/*` -> hooks flag off, `worker` collision, hardcoded model, no MCP.
- kiro -> `agents/*.json`, `skills/*`, `steering/*.md`, `hooks/*.json` -> skill frontmatter missing, invalid `effort`, no MCP servers, hardcoded models.
- antigravity -> `agents/*/agent.md`, `config/rules/*.md`, `config/hooks.json` -> empty prompts, `model: flash` ignores tiers, `colorScheme` unset, undocumented settings keys.
- omp -> `config.yml`, `agents/*.md`, `skills/*`, `hooks.json`, `auth.json`, `SYSTEM.md`, `statusline.json` -> hooks/statusline dead, `effort` should be `thinkingLevel`, YAML settings correct.
- crush -> `crush.json`, `CRUSH.md`, `AGENTS.md`, `skills/*`, `crushrc`, `themes/wallust.json` -> invalid model keys, no per-agent surface, all rules global.
- hermes -> `~/.hermes/config.yaml` plus symlinked skills -> package unmanaged, hook filter/matcher ignored, `hooks_auto_accept = true`.
- copilot -> `agents/*`, `skills/*`, `copilot-instructions.md`, `settings.json` -> no model/effort/theme/trusted-folders settings, MCP no-op, no per-agent model.

## Failure modes
- rbw locked or key absent -> silent `2>/dev/null`, no preflight -> first request 401; OMP/Hermes/Antigravity never load keys.
- Provider outage or model deprecation -> no fallback, no `enabledModels` -> medium/high share one model; Kiro model pin fails the first prompt.
- Context overflow -> OpenCode/Pi defaults only -> no per-agent cap; compaction can drop RDST state.
- Hook failure blocks a tool -> pre-tool fail-open, OpenCode plugin dead -> guard silently does nothing.
- Skill name collision -> `skills.nix:14` `//` replaces base; Pi keeps first discovered -> silent shadowing, no warning.
- Agent drift across harnesses -> empty prompts outside OpenCode; effort vocab mismatch (`effort` vs `thinkingLevel`) -> same agent behaves differently per harness.
- Cost runaway -> no budget cap, `steps` unset -> a loop can spend until quota exhaustion.
- Auth expiry -> no refresh path beyond manual `load-ai-keys` -> long sessions fail mid-turn.
- MCP crash -> no servers today; once added, no restart/health policy -> dead tools until restart.
- Version skew -> `inputs.omp` tracks main, `pi-extensions` git ref unpinned, `inputs.skills` absolute path (`flake.nix:29,54-57`) -> non-reproducible and non-portable.
- Subagent tool stripping -> F1 ordering plus only engineer/worker can write; architect cannot spawn worker (`agents.nix:48-55`) despite `rules.nix:40` -> implementation delegation is unreachable from architect.

## Seams
- Two capability lists and two `rulesText` implementations: `options.nix:411-422,476-483` vs `ai-render.nix:14-31`.
- Drop lists are dead code: `options.nix:34-36` plus six empty `droppedDisciplineRules` locals; only OpenCode honors `dropDisciplines`.
- Seven prompt renderers bypass `agentBodyFor`; one ownership point is missing.
- Five hand-rolled `SKILL.md` builders (`pi:243`, `omp:46`, `kiro:33`, `copilot:45`) duplicate `mkSkillDir`; skill gating exists only in OpenCode and Antigravity.
- Hook protocol reimplemented eight times; `command` ignored twice, `harnesses` ignored by Hermes, `matcher` hardcoded by Crush.
- Model/effort tables hardcoded four times; OpenCode also duplicates provider/model defaults (`opencode.nix:29,154`).
- Skill collisions: `skills.nix:14` silently overrides base skills; `lib/ai-skills.nix:49` flattens nested reference filenames.
- Auth lives in four places: zsh preexec, Pi auth, OMP auth, OpenCode provider env.

## Rejected defaults
- Pi `compaction.*` and `retry.*` defaults (16384/20000, 3 retries) are sane; no override needed.
- OpenCode `snapshot`, `autoupdate`, `small_model` already configured; leave defaults.
- Codex `model_reasoning_effort = "xhigh"` is valid; no need for `minimal`.
- Antigravity `showFeedbackSurvey`/`showTips` already disabled.
- Crush `options.tui.active_theme` and `global_context_paths` are valid; no extra TUI keys needed.
- Copilot `autoUpdate`, `stream`, `respectGitignore` defaults are fine; only model/effort/theme are missing.

## Open questions
- Is `pkgs.opencode` OpenCode 2 in this pin? `programs.opencode.cli` is ignored on v1.
- Does Pi core ship subagents, or only via `pi-extensions`? `~/.pi/agent/agents/*.md` is unconfirmed by Pi docs.
- Are Antigravity frontmatter keys `mainAgent`, `subagent`, and `skills` real, or Gemini CLI leftovers?
- Is `gpt-6-luna` available to this Codex account, and is `worker` allowed as a custom agent name?
- Should `artifacts/repomap.md` be gitignored? Session-start rewrites it in every git repo.
- Should hooks be one binary with `--harness`, or native extensions per harness? The current hybrid is neither.
