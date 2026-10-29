# Renderer Author Matrices & Surface References

## Harness Surface Mapping

- `opencode`:
  - Agent Surface: Native agents (`~/.config/opencode/agents/*.md`)
  - Global Surface: `context` = `""` (Disciplines rendered into agents)
  - Drop Policy: Unslop concise/no-restate/dense
- `pi`:
  - Agent Surface: `agents/*.md`
  - Global Surface: `appendSystem` = Disciplines, `context` = Roster
  - Drop Policy: None
- `codex`:
  - Agent Surface: `.codex/agents/*.toml`
  - Global Surface: `programs.codex.context` = Disciplines
  - Drop Policy: None
- `kiro`:
  - Agent Surface: `.kiro/agents/*.json` (Web stripped for subagents)
  - Global Surface: `.kiro/steering/*.md` = Disciplines
  - Drop Policy: None
- `copilot`:
  - Agent Surface: `~/.config/github-copilot/agents/*.md`
  - Global Surface: `programs.github-copilot-cli.context`
  - Drop Policy: None
- `antigravity`:
  - Agent Surface: `~/.gemini/antigravity-cli/agents/${name}/agent.md`
  - Global Surface: `~/.gemini/config/rules/${name}.md`
  - Drop Policy: None
- `crush`:
  - Agent Surface: None (Single file union in `~/.config/crush/AGENTS.md`)
  - Global Surface: `AGENTS.md` = Briefs + Rules Union + Disciplines
  - Drop Policy: None
- `hermes`:
  - Agent Surface: None
  - Global Surface: Skills `external_dirs` only
  - Drop Policy: None

## Built-In Prompt Overlap Table

- `opencode`:
  - Vendor Default Coverage: Concise output, file reference format
  - Dropped Rules: `unslop.concise`, `unslop.no-restate`, `unslop.dense`
- `crush`:
  - Vendor Default Coverage: Ultra-terse style
  - Dropped Rules: None
- `pi`:
  - Vendor Default Coverage: Unverified
  - Dropped Rules: None
- `codex`:
  - Vendor Default Coverage: Closed base prompt
  - Dropped Rules: None
- `kiro`:
  - Vendor Default Coverage: Closed base prompt
  - Dropped Rules: None
- `copilot`:
  - Vendor Default Coverage: Closed base prompt
  - Dropped Rules: None
- `antigravity`:
  - Vendor Default Coverage: Closed base prompt
  - Dropped Rules: None
- `hermes`:
  - Vendor Default Coverage: Closed base prompt
  - Dropped Rules: None

## Capability & Rules Matrix

- `investigate`: Requires `read` (Target Agents: `ask`, `architect`, `engineer`)
- `research`: Requires `read` (Target Agents: `ask`, `architect`, `engineer`)
- `security`: Requires `read` (Target Agents: `ask`, `architect`, `engineer`)
- `communicate`: Requires `write` (Target Agents: `architect`, `engineer`)
- `style`: Requires `write` (Target Agents: `architect`, `engineer`)
- `verify`: Requires `write`, `execute` (Target Agents: `architect`, `engineer`)
- `linear-history`: Requires `write` (Target Agents: `architect`, `engineer`)
- `signed-commits`: Requires `write` (Target Agents: `architect`, `engineer`)
- `delegate`: Requires `delegate` (Target Agents: `ask`, `architect`, `engineer`)

## Model & Effort Matrix

Tiers are only `low`, `medium`, and `high`. Model names containing `flash` or `pro` are models, not tiers.

- `opencode`:
  - Low: `opencode-go/beam-free`
  - Medium: `opencode-go/beam-free`
  - High: `opencode-go/deepseek-v4.1-flash#max`
  - Effort: variant or `reasoningEffort`
- `pi`:
  - Low: `opencode-go/beam-free`
  - Medium: `opencode-go/deepseek-v4.1-flash`
  - High: `opencode-go/deepseek-v4.1-flash`
  - Effort: `effort`
- `kiro`:
  - Low: `minimax-m2.5`
  - Medium: `claude-haiku-5.5`
  - High: `claude-sonnet-5.5`
  - Effort: not set
- `antigravity`:
  - Low: `flash`
  - Medium: `flash`
  - High: `flash`
  - Effort: global thinking level
- `copilot`:
  - Low: `auto`
  - Medium: `auto`
  - High: `auto`
  - Effort: not set
- `codex`:
  - Low: default
  - Medium: default
  - High: default
  - Effort: `model_reasoning_effort`
- `crush`:
  - Low: `opencode-go/deepseek-v4.1-flash`
  - Medium: `opencode-go/deepseek-v4.1-flash`
  - High: `opencode-go/deepseek-v4.1-flash`
  - Effort: global `reasoning_effort`
- `hermes`:
  - Low: default
  - Medium: default
  - High: default
  - Effort: default

Forbidden by default: `kimi-k3.1-pro`, `gemini-4-argon`, `claude-opus-*`, `kimi-k2.7-code`.

## Hooks Surface Mapping

- `kiro`:
  - Config Target: `.kiro/hooks/ai-hooks.json`
  - Supported Canonical Events: `session-start`, `user-prompt`, `pre-tool`, `post-tool`, `stop`
  - Adapter: `--harness kiro`
- `codex`:
  - Config Target: `.codex/hooks.json`
  - Supported Canonical Events: `session-start`, `user-prompt`, `pre-tool`, `post-tool`, `stop`, `session-end`, `pre-compact`
  - Adapter: `--harness codex`
- `antigravity`:
  - Config Target: `.gemini/config/hooks.json`
  - Supported Canonical Events: `session-start`, `pre-tool`, `post-tool`, `stop`
  - Adapter: `--harness antigravity`
- `crush`:
  - Config Target: `crushrc`
  - Supported Canonical Events: `pre-tool` only
  - Adapter: `--harness crush`
- `hermes`:
  - Config Target: `~/.hermes/config.yaml` `hooks`
  - Supported Canonical Events: `session-start`, `pre-tool`
  - Adapter: `--harness hermes`
- `opencode`:
  - Config Target: `~/.config/opencode/{ai-hooks.json,plugins/ai-hooks.ts}`
  - Supported Canonical Events: `session-start`, `pre-tool`
  - Adapter: `--harness opencode`
- `pi`:
  - Config Target: `~/.pi/agent/hooks.json` via `pi-hooks`
  - Supported Canonical Events: `session-start`, `pre-tool`
  - Adapter: `--harness pi`

Shared commands live in `pkgs/ai-hooks`. Renderers map canonical events and output envelopes; never reimplement guard logic per harness.

## Skills Surface Mapping

- `opencode`:
  - Discovery Target / Configuration: `programs.opencode.settings.skills` (`~/.config/opencode/skills/<name>/`)
  - Rendering Helper: `aiRender.mkSkillDir { prefix = "opencode"; }`
- `antigravity`:
  - Discovery Target / Configuration: `programs.antigravity.settings.skills` (`~/.gemini/antigravity-cli/skills/<name>/`)
  - Rendering Helper: `aiRender.mkSkillDir { prefix = "antigravity"; }`
- `crush`:
  - Discovery Target / Configuration: `programs.crush.settings.skills` (`~/.config/crush/skills/<name>/`)
  - Rendering Helper: `aiRender.mkSkillDir { prefix = "crush"; }`
- `codex`:
  - Discovery Target / Configuration: `programs.codex.settings.skills` (`~/.codex/skills/<name>/`)
  - Rendering Helper: `aiRender.mkSkillDir { prefix = "codex"; }`
- `hermes`:
  - Discovery Target / Configuration: `skills.external_dirs` in `~/.hermes/config.yaml`
  - Rendering Helper: `aiRender.mkSkillDir { prefix = "hermes"; }`
- `pi`:
  - Discovery Target / Configuration: `~/.pi/agent/skills/<name>/`
  - Rendering Helper: `aiRender.mkSkillDir { prefix = "pi"; }`
- `kiro`:
  - Discovery Target / Configuration: `~/.kiro/skills/<name>/`
  - Rendering Helper: `aiRender.mkSkillDir { prefix = "kiro"; }`
- `copilot`:
  - Discovery Target / Configuration: `~/.config/github-copilot/skills/<name>/`
  - Rendering Helper: `aiRender.mkSkillDir { prefix = "copilot"; }`

## Skill Authoring Standard & Anatomy

1. **Trigger Gating**: `description` must define explicit positive and negative activation bounds (*"Load ONLY when... Do NOT load for..."*).
2. **Standard Section Headers**:
   - `## Workflow`: Numbered sequential actions (`1., 2., 3.`) starting with active imperative verbs (`Confirm`, `Inspect`, `Write`, `Implement`, `Stage`). No `X: Y.` category labels.
   - `## Rules`: Bulleted invariant constraints (`- ...`) starting with direct active imperatives (`Never`, `Keep`, `Test`). No buzzword labels (`Iron Law`, `Rule of...`). Final rule is always `- Verify: <exit condition>`.
3. **Artifact Isolation**:
   - `references."<file>.md"`: Static tables, schemas, or templates.
   - `references."examples.md"`: `## Bad` and `## Good` contrast pairs.
   - `scripts."<name>.sh"`: Executable shell tools wrapped by `mkSkillDir`.
