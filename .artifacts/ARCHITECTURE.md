# Architecture

Last verified: 2026-11-18.
Scope: NixOS flake for `lacuna` and `acervus`, standalone Home Manager for `hollowheap`, and the `fovea` nix-on-droid output.

## System Shape

- `flake.nix` delegates to `flake/default.nix`, which enumerates hosts, Home Manager users, nix-on-droid, devShells, packages, apps, and checks.
- NixOS composition: `hosts/<host>` imports one chassis profile, one role, hardware traits, and boot policy.
- `profiles/<class>` sets chassis policy. `roles/<role>/system` composes vertical service slices. `modules/` holds reusable NixOS capability modules.
- `hardware/` holds driver and capability traits. `boot/` holds kernel, bootloader, TPM, secure-boot, and plymouth integration.
- Home Manager is standalone: `home/<user>.nix` imports `home/modules` through `import-tree`; domains are `ai`, `cli`, `core`, `environment`, `programs`, `services`, `terminal`, and `styles`.
- AI harness data flows from `ai.agents`, `ai.skills`, `ai.rules`, `ai.disciplines`, `ai.hooks`, and `programs.mcp.servers` through `home/lib/ai-render.nix` into each harness adapter. Model and effort are adapter-local under `D85`; there is no shared tier table.
- Dynamic Wallust and Noctalia colorschemes own color generation (`D108`); no static palette registry is planned.
- Canonical records and review evidence live in `.artifacts/`, indexed in `.artifacts/REVIEWS.md` (`V01`–`V22`).

## Module Seams

- `flake/default.nix`: composition root for hosts, users, checks, overlays, apps, and Termux outputs. `outputs.lib` and full `tests/` consolidation remain open under `D74`/`D87`.
- `hosts/<host>`: selects profile, role, hardware traits, boot policy, and host-specific secrets.
- `roles/<role>/system`: duty composition; server daemons are vertical slices under `roles/server/system`.
- `modules/`: reusable system modules; hardware- and profile-agnostic.
- `home/hollowheap.nix` plus `home/modules`: user environment composition through `import-tree`. Host-specific HM overlays remain open under `D73`.
- `home/modules/ai/options.nix`: shared AI schema, adapter render helpers, and the single `programs.mcp.servers` registry (`D82`). Pi-only MCP exposure is added in `renderMcpServers`; no private Pi registry remains.
- `home/modules/ai/hooks.nix`: shared hook intent; `dropHooks` removes hooks where harness builtins already enforce the policy (`D81`).
- `home/modules/programs/nvim`: nvf domain modules; LSP in `lsp.nix`, Blink sources and ghost text in `completion.nix`, `r`/`s` prefixes in `keymaps.nix`.
- `modules/options/desktop.nix`: shared `desktop.*` schema; host-specific geometry and Wacom/Yoga switches remain open under `D89`/`D98`.

## Dependency Direction

- `hosts` → `profiles`, `roles`, `hardware`, `boot`.
- `roles` → `modules`.
- `modules` → shared options and libraries; never a host, profile, or role.
- `home/<user>` → `home/modules`; Home Manager stays independent of NixOS evaluation.
- Harness renderers → shared `ai.*` data and `ai-render`; shared data never imports a harness.
- Skills → portable YAML frontmatter and gated references; skill bodies stay harness-neutral.
- Artifacts describe implementation; implementation never depends on artifact state at runtime.

## Framework & Library Choices

- Flake composition uses `flake.nix` plus `import-tree`; Home Manager is standalone and NixOS remains separately applied.
- Desktop composition uses Hyprland, UWSM, Noctalia, and Wallust with shared `desktop.*` options.
- AI harnesses are adapters over one `ai.*` schema. Model and effort literals live in each adapter (`D85`). OpenCode, Pi, Codex, Kiro, Crush, Copilot, Antigravity, Hermes, and Claude Code are consumers, not sources of shared policy.
- Neovim uses `nvf` with domain modules under `home/modules/programs/nvim`.
- Skills use Markdown bodies with portable YAML frontmatter parsed by `lib/ai-skills.nix` and rendered by `home/lib/ai-render.nix`.

## Data & Contracts

- `ai.*` is the contract for agents, skills, rules, disciplines, and hooks. `programs.mcp.servers` is the single MCP registry; Pi adds `codemode` exposure locally (`D82`).
- `desktop.*` provides shared monitors, scale, fonts, compositor geometry, and input policy; host-specific values remain a debt item.
- Wallust templates and Noctalia hooks are the dynamic color contract; base16 syntax roles stay distinct (`D105`).
- MCP server entries require boolean `enabled`; Pi reads `OPENCODE_API_KEY` for both `opencode` and `opencode-go`.
- `Dxx` → `Sxx` → `Txx` remains the traceability chain. Some accepted decisions are not yet converted to specs and tasks.

## Operations & Security

- Home Manager activation and NixOS switch remain separate; verify with dry build or activation build before applying.
- Pre-tool hooks declare git policy; the shared `ai-git-policy` hook is fail-closed, but harness-level matcher coverage remains a debt item.
- Backend daemons bind loopback or mesh addresses; Caddy is the intended ingress boundary.
- Declarative identity uses the GPG auth subkey's SSH public key with `mutableUsers = false` (`D112`).
- Never commit private keys; install-time secrets use ephemeral keys under `D117`.
- `nix flake check`, domain checks, and dry builds must pass before switching.

## Known Debt

- Implemented: `D81`-`D86`, `D99`-`D103`, `D105`-`D107`, `D108`, `D110`-`D120` where code and verification exist.
- Pending: `D70`-`D79` layout, secrets, desktop, hook, MCP, and TLS decisions; `D87`-`D98` flake and desktop fixes; `D104`, `D109`, `D114`-`D116` where verification is incomplete or design is deferred.
- `D110`/`D116` defer HTTPS and fovea access until acervus is installed and supersede `D79`; `D111`/`D117` define the squashfs installer with ephemeral keys.
- Unconverted open decisions remain; route them through the `design` skill before deriving new specs or tasks.
- `my-pi-agent` retains 4 stale and 1 false entry in that upstream repository.

## Evidence

- Requirements: `R01`–`R56` rewritten as observable outcomes on 2026-11-18; retired IDs remain recorded in `REQUIREMENTS.md`.
- Decisions: `D01`–`D120`; superseded `D71`, `D77`, `D78`, and `D79` are closed, with successor links on `D92`, `D82`, `D108`, and `D116`. Open non-superseded decisions still require child specs.
- Reviews: `V01`–`V22`, including whole-system robustness review `V22`.
- Checks: `nix flake check`, `nix build .#checks.x86_64-linux.home .#checks.x86_64-linux.ai-rendered --no-link`, and dry builds passed on 2026-11-18.
- Last boundary update: `/review` robust pass `V22` and user decisions `D81`–`D120`.
