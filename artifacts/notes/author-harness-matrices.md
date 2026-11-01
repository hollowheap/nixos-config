# Harness Author Matrices

## Surfaces

| Harness | Agent surface | Global surface | Drop policy |
|---|---|---|---|
| opencode | `~/.config/opencode/agents/*.md` | none; disciplines render into agents | unslop concise/no-restate/dense |
| pi | `agents/*.md` | `appendSystem` disciplines; `context` roster | none |
| codex | `.codex/agents/*.toml` | `programs.codex.context` disciplines | none |
| kiro | `.kiro/agents/*.json`; web stripped for subagents | `.kiro/steering/*.md` disciplines | none |
| copilot | `~/.config/github-copilot/agents/*.md` | `programs.github-copilot-cli.context` | none |
| antigravity | `~/.gemini/antigravity-cli/agents/<name>/agent.md` | `~/.gemini/config/rules/<name>.md` | none |
| crush | none; union in `~/.config/crush/AGENTS.md` | briefs + rules union + disciplines | none |
| hermes | none | skills `external_dirs` only | none |

## Built-in overlap

| Harness | Vendor default | Dropped rules |
|---|---|---|
| opencode | concise output, file references | `unslop.concise`, `unslop.no-restate`, `unslop.dense` |
| crush | ultra-terse style | none |
| pi, codex, kiro, copilot, antigravity, hermes | unverified or closed | none |

## Capability and rules

| Rule | Requires | Target agents |
|---|---|---|
| investigate, research, security | `read` | ask, architect, engineer |
| communicate, style, linear-history, signed-commits | `write` | architect, engineer |
| verify | `write` + `execute` | architect, engineer |
| delegate | `delegate` | ask, architect, engineer |

## Models and effort

Only `low`, `medium`, and `high` are tiers. `flash`/`pro` are model names.

| Harness | Low | Medium | High | Effort |
|---|---|---|---|---|
| opencode | `opencode-go/beam-free` | `opencode-go/beam-free` | `opencode-go/deepseek-v4.1-flash#max` | variant or `reasoningEffort` |
| pi | `opencode-go/beam-free` | `opencode-go/deepseek-v4.1-flash` | `opencode-go/deepseek-v4.1-flash` | `effort` |
| kiro | `minimax-m2.5` | `claude-haiku-5.5` | `claude-sonnet-5.5` | not set |
| antigravity | `flash` | `flash` | `flash` | global thinking level |
| copilot | `auto` | `auto` | `auto` | not set |
| codex | default | default | default | `model_reasoning_effort` |
| crush | `opencode-go/deepseek-v4.1-flash` | same | same | global `reasoning_effort` |
| hermes | default | default | default | default |


## Hooks

| Harness | Target | Canonical events | Adapter |
|---|---|---|---|
| kiro | `.kiro/hooks/ai-hooks.json` | session-start, user-prompt, pre-tool, post-tool, stop | `--harness kiro` |
| codex | `.codex/hooks.json` | session-start, user-prompt, pre-tool, post-tool, stop, session-end, pre-compact | `--harness codex` |
| antigravity | `.gemini/config/hooks.json` | session-start, pre-tool, post-tool, stop | `--harness antigravity` |
| crush | `crushrc` | pre-tool | `--harness crush` |
| hermes | `~/.hermes/config.yaml` hooks | session-start, pre-tool | `--harness hermes` |
| opencode | `~/.config/opencode/{ai-hooks.json,plugins/ai-hooks.ts}` | session-start, pre-tool | `--harness opencode` |
| pi | `~/.pi/agent/hooks.json` via `pi-hooks` | session-start, pre-tool | `--harness pi` |

Shared commands live in `home/modules/ai/hooks.nix`. Renderers map events and native envelopes; never reimplement guard logic per harness.

## Skills

| Harness | Discovery target | Helper |
|---|---|---|
| opencode | `programs.opencode.settings.skills` | `mkSkillDir { prefix = "opencode"; }` |
| antigravity | `programs.antigravity.settings.skills` | prefix `antigravity` |
| crush | `programs.crush.settings.skills` | prefix `crush` |
| codex | `programs.codex.settings.skills` | prefix `codex` |
| hermes | `skills.external_dirs` | prefix `hermes` |
| pi | `~/.pi/agent/skills/<name>/` | prefix `pi` |
| kiro | `~/.kiro/skills/<name>/` | prefix `kiro` |
| copilot | `~/.config/github-copilot/skills/<name>/` | prefix `copilot` |

## Authoring standard

- Description sets positive and negative trigger bounds; do not omit the trigger.
- Body uses `## Workflow` with numbered active-verb steps and `## Rules` with imperative invariants.
- Final rule is `- Verify: <exit condition>`.
- Static formats/tables belong in `references/*.md`; contrast pairs in `examples.md`; executable tools in `scripts/`.
- Use `aiRender.mkSkillDir`; never hand-build per-harness skill trees.
