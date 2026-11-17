# Architecture

Last verified: 2026-11-18.
Scope: NixOS flake for `lacuna` and `acervus`, standalone Home Manager for `hollowheap`, and the `fovea` nix-on-droid output.

## System Shape

- `flake.nix` delegates to `flake/default.nix`, which enumerates hosts, Home Manager users, nix-on-droid, devShells, packages, apps, and checks.
- NixOS composition: `hosts/<host>` imports a profile, role, hardware modules, and boot policy.
- `profiles/<class>` sets chassis policy. `roles/<role>/system` composes vertical service slices. `modules/` holds reusable NixOS capability modules.
- `hardware/` holds driver and capability traits. `boot/` holds kernel, bootloader, TPM, secure-boot, and plymouth integration.
- Home Manager is standalone: `home/<user>.nix` imports `home/modules` through `import-tree`; domains are `ai`, `cli`, `core`, `environment`, `programs`, `services`, `terminal`, and `styles`.
- AI harness data flows from `ai.agents`, `ai.skills`, `ai.rules`, `ai.disciplines`, `ai.hooks`, and `programs.mcp.servers` through `home/lib/ai-render.nix` into each harness adapter. Model and effort are adapter-local under `D85`; there is no shared tier table.
- Canonical architecture, requirements, decisions, specs, tasks, and review evidence live in `.artifacts/`, indexed in `.artifacts/REVIEWS.md` (`V01`–`V15`, seam reviews `V16`–`V21`, whole-system review `V22`) with design notes under `.artifacts/notes/`.

## Module Seams

- `flake/default.nix`: host and user discovery, `outputs.lib` export, and composition root; checks delegate into `tests/default.nix` (`D74`) and host/boot external modules import in their owning role/boot/HM modules.
- `hosts/<host>`: the only place that selects profile, role, hardware, boot traits, and host-specific `secrets/*.yaml` (`D70`) for a machine.
- `profiles/<class>`: chassis policy; no service implementation and no hardware drivers (`HandleLidSwitch = "suspend-then-hibernate"` paired with caffeine lock override per `D71`).
- `roles/<role>/system`: duty composition and vertical service slices; `roles/desktop/system` consumes `desktop.primaryOutput`, XKB `variant`/`options`, and system fonts (`D73`).
- `modules/`: reusable system modules; hardware- and profile-agnostic; `modules/security/sops.nix` binds shared `secrets/common.yaml` (`D70`).
- `hardware/` and `boot/`: platform capabilities and boot integration.
- `home/hollowheap.nix` plus `home/modules`: user environment composition (`import-tree`); `home/hosts/lacuna` / host-trait overlays hold machine-specific display/Wacom/Yoga overrides cleanly separated from shared HM modules (`D73`), and `home/modules/programs/nvim/lsp.nix` owns editor language/linter wiring.
- `home/modules/ai/options.nix`: shared AI schema, including `programs.mcp.servers` (`D77`: 8 harnesses mapped, Pi exempt via `D62`), `worker` write-capability rule/discipline gating (`D76`), and `ai.render.agentBodyFor`. `lib/ai-skills.nix` parses multi-paragraph YAML blocks and bullet `agents` lists (`D76`).
- `home/modules/ai/hooks.nix`: repomap commands (`.artifacts/REPOMAP.md`) and `ai-git-policy`; `ai.hooks` provides per-harness tool matchers (`D76`).
- Dynamic Wallust and Noctalia colorschemes own color generation (`D108`); no static palette registry is planned.
- `inputs.iridescent`: workflow lifecycle skills and `iridescent-artifacts` verifier/CLI. `pkgs/repomap.nix`: generated `.artifacts/REPOMAP.md` symbol map.
- `modules/options/desktop.nix`: hardware-neutral shared `desktop.*` schema (`D73`).

## Dependency Direction

- `hosts` → `profiles`, `roles`, `hardware`, `boot`.
- `roles` → `modules`.
- `modules` → shared options and libraries; never a host, profile, or role.
- `home/<user>` → `home/modules` + optional host-trait overlay (`D73`); Home Manager stays independent of NixOS evaluation.
- Harness renderers → shared `ai.*` data and `ai-render`; shared data never imports a harness; read-only rules gate on `!agent.capabilities.write` (`D76`).
- Skills → portable YAML frontmatter and gated references; skill bodies stay harness-neutral (`retro`, `corpus-audit`, `omp` retired under `D72`).
- Artifacts describe implementation; implementation never depends on artifact state at runtime.

## Framework & Library Choices

- Flake composition uses `flake.nix` plus `import-tree`; Home Manager is standalone and NixOS remains separately applied.
- Desktop composition uses Hyprland, UWSM, Noctalia, and Wallust with shared `desktop.*` options.
- AI harnesses use Home Manager renderers over one `ai.*` schema; every renderer uses `aiRender.agentBodyFor`. Model and effort are set directly in each adapter under `D85`; no shared `ai.tiers` table exists. OpenCode, Pi, Codex, Kiro, Crush, Copilot, Antigravity, Hermes, and Claude Code are adapters, not sources of shared policy.
- Neovim uses `nvf` with domain modules under `home/modules/programs/nvim`.
- Skills use Markdown bodies with portable YAML frontmatter (`name`, `description`, `disable-model-invocation`, `agents`) parsed by `lib/ai-skills.nix` and rendered per harness by `home/lib/ai-render.nix`; `iridescent` supplies lifecycle skills and `iridescent-artifacts`, and `opal` supplies `ui-probe` and UI rules.

## Data & Contracts

- `ai.*` is the contract for agents, skills, rules, disciplines, and hooks; harness files are derived (`D76`). Model and effort are adapter-local (`D85`). `programs.mcp.servers` is the single MCP registry and must render into every capable adapter, including Pi (`D82`). `ai.hooks` owns intent, command, matcher, and harness filter semantics, with adapters dropping hooks already provided by harness builtins (`D81`).
- `desktop.*` in `modules/options/desktop.nix` provides neutral defaults for monitors, scale, fonts, compositor geometry, and input policy; host values live in `hosts/<host>/` and HM host-trait overlays (`D73`).
- Wallust templates and Noctalia hooks are the dynamic color contract (`D108`); D105 keeps base16 syntax roles visually distinct.
- `tmux` restores `Ctrl-D` EOF via prefix `d` while retaining root `C-g`/`C-y`/`C-b`, bare single-letter Zsh global aliases, and `D69` `C-p`/`C-n` (`D75`).
- Traceability artifacts own accepted decisions and requirements: `Dxx` → `Sxx` → `Txx`.
- `Secrets partition via sops-nix` (`D70`): `secrets/common.yaml` (`lacuna` + `acervus`) and `secrets/lacuna.yaml` (server-only); user secrets arrive via `vaultwarden`, `rbw`, and `gpg-agent`. AI harness OpenCode keys inject per agent child process via `config.ai.render.wrapWithOpenCodeKey` (`D80`), avoiding parent Zsh shell leakage.
- Caddy terminates TLS via DuckDNS DNS-01 (`caddy-dns/duckdns`) for both public and `*.hollowheap.duckdns.org` internal mesh vhosts (`D79`), removing static `tls internal` PKI workarounds.

## Operations & Security

- OpenCode puts `* = "deny"` first and derives allows from capabilities; read-only subagent rules gate strictly on `!agent.capabilities.write` (`D76`).
- Pre-tool hooks must fail closed on malformed JSON (`ai-git-policy` and Kiro `prevent-overwrite`), and Kiro `architect` allows canonical `.artifacts/*.md` paths (`D76`).
- Home Manager activation and NixOS switch remain separate; verify dry-build or activation build before applying.
- Laptop lid close defaults to `suspend-then-hibernate` and locks instead when Noctalia caffeine inhibitor is active (`D71`).
- Internal services bind loopback or mesh addresses; Caddy is the ingress boundary with DNS-01 trusted certs (`D79`) and Headscale `acl.hujson` permitting mesh SSH port `22`.
- Commit and tag signing stay enabled; `rbw-agent`, `rclone`, `git-maintenance`, and `store-hygiene` units align restart policies, delete caps (`R39`), and rollback retention (`14d`).

## Known Debt

- **Accepted, pending implementation (`D81`-`D109`)**: whole-system review `V22` resolved all design forks. Work is queued by decision ID:
  - `D81`-`D86`: hook builtin adaptation, shared MCP registry, Codex without recompilation, Kiro adapter neutrality, adapter-local model/effort, and repomap removal.
  - `D87`: all V16 flake-seam findings must be fixed.
  - `D88`-`D98`: lacuna-only HDR, host-scoped geometry, greeter parity, separate touch abstractions, caffeine supersession, frame-rate-aware power saving, NixOS fonts, `barHeight` removal, Hyprland portal, full Wallust template checks, and host-scoped Wacom/Yoga switches.
  - `D99`-`D109`: unified Markdown formatter contract, no Neovim session restore, ACP provider registration, bash/zsh formatters, Noctalia started hook, distinct base16 roles, evaluated editor checks, dead helper removal, dynamic colorscheme authority, and ACP provider enumeration.
- **Unresolved implementation findings from `V22`**: fail-closed git policy hook, SSH agent and pinentry paths, declarative SSH credentials, sops partitioning, DNS-01 on all client vhosts, Headscale ingress and ACL, raw `wlan0` ports, rclone lifecycle guards, generation retention, and stale static checks.
- **`my-pi-agent` specs**: retain 4 stale and 1 false entry left to that upstream repo.

## Evidence

- `.artifacts/REQUIREMENTS.md`: `R01`–`R56` (`R18`/`R19`/`R23` retired per `D72`; `R12`/`R32`/`R33`/`R53` reconciled).
- `.artifacts/DECISIONS.md`: accepted decisions through `D80`.
- `.artifacts/REVIEWS.md`: slice reviews `V01`–`V15`, seam reviews `V16`–`V21`, and whole-system review `V22` under `.artifacts/review/`.
- `AGENTS.md`: repository conventions and essential commands.
- `tests/`: flake checks (`layout`, `policy`, `boot`, `hardware`, `services`, `users`, `home`, `skills`, `nix-on-droid`).
- Last boundary update: `/review` robust pass `V22` and user decisions `D81`–`D109`.
