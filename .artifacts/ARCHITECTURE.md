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
- `home/hollowheap.nix` plus `home/modules`: user environment composition through `import-tree`. Host overlays live in `home/hosts/<host>.nix`; refinement stays open under `D73`/`D89`/`D98`.
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
- MCP server entries require boolean `enabled`; Pi receives only `opencode-go`, while OpenCode and Crush keep both providers (`D119`).
- Pi's `decide` tool uses `opencode/jev-1.13-free` with `timeoutMs = 5000` from declarative `decide.json`.
- `Dxx` → `Sxx` → `Txx` remains the traceability chain. Some accepted decisions are not yet converted to specs and tasks.

## Operations & Security

- Home Manager activation and NixOS switch remain separate; verify with dry build or activation build before applying.
- Pre-tool hooks declare git policy; the shared `ai-git-policy` hook is fail-closed, but harness-level matcher coverage remains a debt item.
- Backend daemons bind loopback or mesh addresses; Caddy is the intended ingress boundary.
- Declarative identity uses the GPG auth subkey's SSH public key with `mutableUsers = false` (`D118`).
- Never commit private keys; install-time secrets use ephemeral keys under `D117`.
- `nix flake check`, domain checks, and dry builds must pass before switching.

## Known Debt

- Implemented: `D81`-`D86`, `D99`-`D103`, `D105`-`D108`, `D110`-`D116`, and `D118`-`D122` where code and verification exist.
- Pending: unresolved `Dxx` remain in `DECISIONS.md`; route open records through `design`/`specify`/`plan` and refresh this snapshot after migration.
- `D110`/`D116` defer HTTPS and fovea access until acervus is installed and supersede `D79`; `images.acervus` and `.#install-acervus` are shipped, while the `D117` ephemeral-key design remains open.
- Unconverted open decisions remain; route them through the `design` skill before deriving new specs or tasks.
- `my-pi-agent` retains 4 stale and 1 false entry in that upstream repository.

## Evidence

- Requirements: `R01`–`R56` rewritten as observable outcomes on 2026-11-18; retired IDs remain recorded in `REQUIREMENTS.md`.
- Decisions: `D01`–`D122`; superseded `D71`, `D77`, `D78`, `D79`, and `D88` are closed, with successor links on `D92`, `D82`, `D108`, `D116`, and `D122`. Open non-superseded decisions still require child specs.
- Reviews: `V01`–`V22`, including whole-system robustness review `V22`.
- Checks: `nix flake check`, `nix build .#checks.x86_64-linux.home .#checks.x86_64-linux.ai-rendered .#checks.x86_64-linux.skills-rendered --no-link`, and dry builds passed on 2026-11-18.
- Last boundary update: `/review` robust pass `V22` and user decisions `D81`–`D122`.
