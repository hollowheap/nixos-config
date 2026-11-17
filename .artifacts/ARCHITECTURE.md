# Architecture

Last verified: 2026-11-15.
Scope: NixOS flake for `lacuna` and `acervus`, standalone Home Manager for `hollowheap`, and the `fovea` nix-on-droid output.

## System Shape

- `flake.nix` delegates to `flake/default.nix`, which enumerates hosts, Home Manager users, nix-on-droid, devShells, packages, apps, and checks.
- NixOS composition: `hosts/<host>` imports a profile, role, hardware modules, and boot policy.
- `profiles/<class>` sets chassis policy. `roles/<role>/system` composes vertical service slices. `modules/` holds reusable NixOS capability modules.
- `hardware/` holds driver and capability traits. `boot/` holds kernel, bootloader, TPM, secure-boot, and plymouth integration.
- Home Manager is standalone: `home/<user>.nix` imports `home/modules` through `import-tree`; domains are `ai`, `cli`, `core`, `environment`, `programs`, `services`, `terminal`, and `styles`.
- AI harness data flows from `ai.agents`, `ai.skills`, `ai.rules`, `ai.disciplines`, `ai.hooks`, and `programs.mcp.servers` through `home/lib/ai-render.nix` into each harness adapter.
- Canonical architecture, requirements, decisions, specs, tasks, and review evidence live in `.artifacts/`, indexed in `.artifacts/REVIEWS.md` (`V01`–`V15`, seam reviews `V16`–`V20`) with design notes under `.artifacts/notes/`.

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
- `home/modules/styles/palette.nix` (`D78`): canonical monochrome neutral ramp and contrast helpers feeding `styles.pills` and Wallust/Noctalia hooks.
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
- AI harnesses use Home Manager renderers over one `ai.*` schema; every renderer uses `aiRender.agentBodyFor` and the `ai.tiers` model/effort table. OpenCode, Pi, Codex, Kiro, Crush, Copilot, Antigravity, Hermes, and Claude Code are adapters, not sources of shared policy.
- Neovim uses `nvf` with domain modules under `home/modules/programs/nvim`.
- Skills use Markdown bodies with portable YAML frontmatter (`name`, `description`, `disable-model-invocation`, `agents`) parsed by `lib/ai-skills.nix` and rendered per harness by `home/lib/ai-render.nix`; `iridescent` supplies lifecycle skills and `iridescent-artifacts`, and `opal` supplies `ui-probe` and UI rules.

## Data & Contracts

- `ai.*` is the contract for agents, skills, rules, disciplines, hooks, models, capabilities, and tier routing; harness files are derived (`D76`). `programs.mcp.servers` covers OpenCode, Claude Code, Codex, Crush, Copilot, Kiro, Antigravity, and Hermes, with Pi exempt under `D62` (`D77`). `ai.hooks` owns command/matcher/harness filter semantics.
- `desktop.*` in `modules/options/desktop.nix` provides neutral defaults for monitors, scale, fonts, compositor geometry, and input policy; host values live in `hosts/<host>/` and HM host-trait overlays (`D73`).
- `styles/palette.nix` owns shared neutral ramp constants and contrast helpers bridging Noctalia M3 and Wallust ANSI-16 (`D78`).
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

- **Pending implementation (`D70`, `D71`, `D73`–`D79`)**: Architecture decisions above are accepted and queued for `/specify` -> `/plan` -> `/implement`:
  - `V16`/`V11` (`D74`): Move `ai-rendered`/`skills-rendered` into `tests/`, add HM `unfreePackages`, export `outputs.lib`, and wire `fovea` overlays/`extraSpecialArgs`.
  - `V17`/`V08` (`D71`, `D73`): Neutralize `modules/options/desktop.nix`, fix `desktop.shortcuts` open dispatch, fix `roles/desktop/system` hardcodes (`eDP-1`/variant/options/fonts), wire `HandleLidSwitch` + caffeine lock, and extract Wacom/Yoga defaults out of shared HM.
  - `V18`/`V01` (`D76`, `D77`): Fix `worker` read-only contradiction, `lib/ai-skills.nix` YAML parser, Kiro `architect` globs/hooks/`efforts.kiro`, `hermes.nix` enable/agents, `pre-tool` matchers, and 3 additional MCP adapters.
  - `V19`/`V09`/`V03` (`D70`, `D79`): Split `secrets.yaml` into `common.yaml`/`lacuna.yaml`, switch Vaultwarden/Headscale Caddy vhosts to DNS-01 (`D79`), restart `NetworkManager-ensure-profiles.service` on secret change, open mesh TCP `22` in `acl.hujson`, and align `IdentityAgent`/tag-push checks (`D80` OpenCode key wrappers completed).
  - `V10`/`V12`/`V13`/`V20`/`V05`/`V02`/`V07` (`D75`, `D78`): Add `styles/palette.nix`, EOF-safe `pill_load_wallust`, unconditional Neovim `SIGUSR1`, cold-start `wallustRender`, Zsh `$XDG_CACHE_HOME` fallback, prefix `C-d` in tmux, `rclone`/`rbw-agent`/`health-check`/`store-hygiene` fixes, `boot/secure-boot.nix` fail-closed key check, `hardware/nvidia.nix` PRIME scoping, and `nvfLanguages.markdown.enable` formatter fix.
- **`my-pi-agent` specs**: retain 4 stale and 1 false entry left to that upstream repo.

## Evidence

- `.artifacts/REQUIREMENTS.md`: `R01`–`R56` (`R18`/`R19`/`R23` retired per `D72`; `R12`/`R32`/`R33`/`R53` reconciled).
- `.artifacts/DECISIONS.md`: accepted decisions through `D80`.
- `.artifacts/REVIEWS.md`: slice reviews `V01`–`V15`, cross-cutting seam reviews `V16`–`V20`, and modular-tangling review `V21` under `.artifacts/review/`.
- `AGENTS.md`: repository conventions and essential commands.
- `tests/`: flake checks (`layout`, `policy`, `boot`, `hardware`, `services`, `users`, `home`, `skills`, `nix-on-droid`).
- Last boundary update: `/design` pass resolving `V01`–`V20` forks (`D70`–`D79`).
