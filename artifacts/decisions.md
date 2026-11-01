# Architectural Decisions

### System

- [x] D01 [R01]: Use Layout A class-separated trees and merge Home Manager into `home/`.
  - Alternatives: a full dendritic flake, or an external Home Manager repository.
  - Consequences: `home/modules/{ai,core,environment,programs,services,shell,styles}` share one lockfile.
  - One evaluation keeps the system and user layers reviewable together.
  - Arch: System Shape

- [x] D02 [R02]: Keep release-26.05 as the primary nixpkgs, with `pkgs.unstable`, the kernel, Home Manager, and user programs on unstable.
  - Alternatives: unstable primary with stable hardware, or all-stable.
  - Consequences: standalone Home Manager uses unstable packages; NixOS stays stable.
  - Stable drivers avoid regressions while desktop programs track current nixpkgs.
  - Arch: System Shape

- [x] D03 [R03]: Hosts import one chassis profile, role modules, and explicit hardware and boot traits.
  - Alternatives: per-host conditionals or fused profile+role bundles.
  - Consequences: `hosts/<name>/default.nix` stays a short composition list.
  - Imports express chassis, duty, and capability without `config.profile` checks.
  - Arch: System Shape

- [x] D04 [R04]: Treat touch and HDR as hardware traits that bridge into Home Manager.
  - Alternatives: duplicate host checks in compositor modules.
  - Consequences: standalone Home Manager sets both flags for lacuna; hardware traits record host capability.
  - Hardware capabilities gate compositor behavior without host-specific branches.
  - Arch: System Shape

- [x] D05 [R04]: Lacuna is Intel Arc only; acervus uses hybrid Intel + Nvidia PRIME.
  - Alternatives: one graphics trait for both hosts.
  - Consequences: acervus imports `hardware/hybrid-gpu.nix`; lacuna does not.
  - Matches the actual PCI hardware while keeping lacuna's driver surface minimal.
  - Arch: System Shape

- [x] D06 [R05]: Split boot integration into `boot/{kernel,grub,tpm,secure-boot,minegrub,plymouth}.nix`.
  - Alternatives: one `boot.nix`, or systemd-boot.
  - Consequences: hosts import only the boot components they need.
  - Platform integration stays separate from hardware capabilities.
  - Arch: System Shape

- [x] D07 [R05]: Use Disko with GPT, LUKS, and BTRFS subvolumes for lacuna.
  - Alternatives: imperative partitioning or a single ext4 root.
  - Consequences: the host owns `disko.nix`; acervus keeps a placeholder until install.
  - Declarative encryption and subvolumes make recovery and rollback auditable.
  - Arch: System Shape

- [x] D11 [R07]: Keep Hyprland, UWSM, and the Noctalia greeter system-managed while Home Manager owns the user session.
  - Alternatives: let Home Manager install the compositor and portal.
  - Consequences: Home Manager sets `package = null` and `portalPackage = null`.
  - The login path remains stable while user configuration iterates.
  - Arch: System Shape

- [x] D14 [R09]: Expose `nixOnDroidConfigurations.fovea` from a root nix-on-droid config on unstable aarch64.
  - Alternatives: a `hosts/fovea` NixOS directory, or no Termux output.
  - Consequences: Termux stays outside NixOS host enumeration.
  - Termux needs a standalone profile, not NixOS boot or hardware modules.
  - Arch: System Shape

- [x] D18 [R05]: Run acervus as a headless laptop with lid close ignored and suspend disabled; no charge threshold.
  - Alternatives: desktop power policy on the server, or battery caps.
  - Consequences: power policy lives in the acervus host module.
  - The server stays reachable when the lid closes, without unwanted battery caps.
  - Arch: System Shape

- [x] D25 [R05]: Use a 3-second GRUB timeout and a matching Minegrub main-menu timeout.
  - Alternatives: keep the packaged 15-second timeout.
  - Consequences: `boot.loader.timeout` and the theme config agree.
  - Users get enough time to pick a generation without a long wait.
  - Arch: System Shape

- [x] D26 [R04]: Include i915 early KMS and `i915.fastboot=1` in the Intel graphics trait.
  - Alternatives: late KMS with panel reinitialization.
  - Consequences: `hardware/graphics.nix` owns the kernel module and parameter.
  - Early KMS avoids the black-screen handoff into Plymouth and the greeter.
  - Arch: System Shape

- [x] D27 [R05]: Use systemd initrd with TPM2 unlock and PCR measurement.
  - Alternatives: passphrase-only initrd.
  - Consequences: `boot/tpm.nix` owns crypttab options, `tpm_tis`, and PCR phases.
  - TPM-bound unlock avoids retyping the passphrase on the trusted host.
  - Arch: System Shape

- [x] D29 [R05]: Keep Minegrub packages in `pkgs/` and theme selection in `boot/minegrub.nix`.
  - Alternatives: a hardware minegrub module.
  - Consequences: package declarations stay separate from boot aesthetics.
  - Only lacuna imports the theme.
  - Arch: System Shape

- [x] D34 [R05]: Keep laptop thermal and power policy in `profiles/laptop/default.nix`.
  - Alternatives: hardware traits owning thermald and upower.
  - Consequences: the profile enables thermald, upower, and power-profiles-daemon.
  - Chassis policy stays separate from capability.
  - Arch: System Shape

### Module

- [x] D13 [R08]: Define a neutral verb-object shortcut catalog and render it in Hyprland.
  - Alternatives: hardcode every keybind in the compositor module.
  - Consequences: compositor modules map action names to native dispatchers.
  - One catalog can later feed Niri or another compositor.
  - Arch: Module Seams

- [x] D12 [R08]: Split `home/cli.nix` for shared options from `home/gui.nix` for the compositor and visual tier.
  - Alternatives: one monolithic Home Manager tree.
  - Consequences: CLI-only hosts can import the baseline without GUI modules.
  - Superseded by D46's recursive import-tree layout.
  - Arch: Module Seams

- [x] D15 [R10]: Enforce structural invariants with flake checks.
  - Alternatives: prose-only specs.
  - Consequences: layout drift fails `nix flake check`.
  - Shell checks catch accidental profile, role, boot, and Home Manager drift.
  - Arch: Module Seams

- [x] D41 [R15]: Keep domain checks under `tests/` with a recursive loader and one derivation per domain.
  - Alternatives: one large inline `runCommand` in `flake/default.nix`.
  - Consequences: `tests/default.nix` maps each file to `checks.x86_64-linux.<name>`.
  - Splitting by domain isolates failures and keeps flake composition small.
  - Arch: Module Seams

- [x] D42 [R16]: Port the shell and terminal toolset before adding GUI app bundles or prompt theming.
  - Alternatives: keep every Home Manager module in one tree.
  - Consequences: zsh, zoxide, git, direnv, tealdeer, and core tools live under `home/modules/terminal`; they have no GUI dependency. D60 later split terminal, CLI, and program modules.
  - A CLI-only host must be useful without a compositor or theme generator.
  - Arch: Module Seams

- [x] D43 [R17]: Port remaining Home Manager modules in functional slices and mark parity only after each slice evaluates.
  - Alternatives: copy every module at once.
  - Consequences: prompt theming, GUI apps, editor/AI, and auxiliary services land independently.
  - Most sibling modules are still absent; the current completed tasks cover infrastructure and the visual baseline only.
  - Arch: Module Seams

- [x] D16 [R02]: Expose `unfreePackages` as a declarable list merged into `allowUnfreePredicate`.
  - Alternatives: one hardcoded unfree list.
  - Consequences: owning modules append the names they need.
  - Package licensing becomes explicit at the module boundary.
  - Arch: Module Seams

- [x] D17 [R03]: Compose `users.adminExtraGroups` into every admin and let owning modules append their group.
  - Alternatives: hardcode every group in `modules/system/users.nix`.
  - Consequences: Podman, Wi-Fi, RGB, TPM, and graphics modules own their groups.
  - Hosts that omit a module do not receive stale group memberships.
  - Arch: Module Seams

- [x] D21 [R11]: Split optional apps into `home/modules/programs/gaming` and keep PrismLauncher out of the CLI baseline.
  - Alternatives: install every GUI app globally.
  - Consequences: gaming apps are explicit host or role imports.
  - Optional apps must not expand CLI-only hosts.
  - Arch: Module Seams

- [x] D35 [R01]: Keep recursive module discovery in `lib/default.nix`.
  - Alternatives: manual imports in every directory.
  - Consequences: `modules/default.nix` uses `mkModuleLoader`.
  - New modules are picked up without loader boilerplate.
  - Arch: Module Seams

- [x] D36 [R01]: Keep the package overlay in `pkgs/default.nix` with directory camelCasing.
  - Alternatives: a hardcoded package list.
  - Consequences: file names stay kebab-case; directory scopes become camelCase.
  - Local packages are exposed without editing an index.
  - Arch: Module Seams

- [x] D37 [R01]: Keep language devShells in `flake/devshells.nix` on unstable.
  - Alternatives: global toolchain installs.
  - Consequences: shells stay flake-local and are not host packages.
  - Toolchains remain isolated per project.
  - Arch: Module Seams

- [x] D44 [R08]: Organize Home Manager implementation modules by domain under `home/modules/{ai,core,environment,programs,services,shell,styles}`.
  - Alternatives: tier directories under `home/modules/{cli,gui,apps}`, or a flat module tree.
  - Consequences: domain modules load without a central file list.
  - Superseded entrypoint details by D46.
  - Arch: Module Seams

- [x] D45 [R08]: Name per-user Home Manager entrypoints after the account and discover them from `home/*.nix`.
  - Alternatives: one generic `home.nix` with inline user identity, or a hardcoded user list in the flake.
  - Consequences: `home/hollowheap.nix` owns identity and imports; a future `home/steve.nix` is discovered automatically.
  - User files express identity while shared domain modules stay reusable.
  - Arch: Module Seams

- [x] D46 [R08]: Load Home Manager modules recursively with `import-tree` and centralize shared desktop values in `modules/options/desktop.nix`.
  - Alternatives: explicit `home/cli.nix` and `home/gui.nix` import lists, or duplicated Hyprland and greeter values.
  - Consequences: no central module list; Hyprland and the greeter read the same monitors, primary output, scale, and fonts.
  - Modules own their options and wiring; only genuinely shared data is centralized.
  - Arch: Module Seams

- [x] D47 [R08]: Keep Hyprland binds and submaps in `home/modules/programs/hyprland/keybinds.nix`, with shared Lua helpers in `home/lib/hyprland.nix`.
  - Alternatives: duplicate the bind table in each host's compositor module.
  - Consequences: any Home Manager configuration using `import-tree` gets the same keybinds; host-specific compositor settings stay separate.
  - Shared interaction policy without a centralized host list.
  - Arch: Module Seams

- [x] D48 [R08]: Keep compositor window dimensions in `home/modules/environment/compositor.nix` under `desktop.compositor`.
  - Alternatives: keep dimensions under `styles.dims` or Hyprland-specific options.
  - Consequences: Hyprland and Noctalia consume the same gaps, borders, radius, and bar height.
  - Compositor geometry is not a theme token or a program-specific setting.
  - Arch: Module Seams

- [x] D59 [R21]: Vertical domain slices for server role daemons.
  - Alternatives: maintain monolithic `roles/server/system/default.nix` with hardcoded reverse proxy ports and secrets.
  - Consequences: `roles/server/system/` decomposes into `caddy.nix`, `headscale.nix`, `vaultwarden.nix`, and `ddclient.nix`, tied together by `default.nix`; each service declares its own `services.caddy.virtualHosts` block, ports, and restart units.
  - Enables open-closed extensibility where adding or modifying a service touches only its dedicated slice without mutating the reverse proxy monolith.
  - Arch: Module Seams

- [x] D60 [R22]: Decoupled home module taxonomy across terminal, cli, and programs.
  - Alternatives: mix interactive shells, headless utilities, and GUI/AI apps inside a bloated `home/modules/programs/`.
  - Consequences: `home/modules/terminal` holds shell runtime, prompts, and multiplexers (`zsh`, `starship`, `tmux`, `zoxide`, `direnv`); `home/modules/cli` holds standalone headless utilities (`git`, `lazygit`, `bat`, `btop`, `yazi`, `fastfetch`, `tealdeer`, `gpg`, `ssh`); `home/modules/programs` retains complex desktop suites, editors, and AI harnesses.
  - Creates clear cohesion boundaries matching process lifecycle and user interaction model while leaving `import-tree` auto-discovery intact.
  - Arch: Module Seams

- [x] D24 [R14]: Add long-press, multi-finger, and edge gestures to the touch compositor module.
  - Alternatives: keep only workspace swipe and the on-screen keyboard bind.
  - Consequences: gestures map to window, launcher, and workspace actions.
  - Touch navigation should cover common window management without a keyboard.
  - Arch: Module Seams

- [x] D52 [R20]: Dual clipboard yank mappings (`ry` and `<leader>y`) with native register access.
  - Alternatives: restrict clipboard yank exclusively to `ry` operator or `<leader>y` leader map; keep `"` cleared.
  - Consequences: both `ry` and `<leader>y` (with `yy` and `Y` variants) yank to system clipboard (`"+y`), restoring symmetry with `<leader>p`/`<leader>P`; removing `"` from `<Nop>` clears restores native register prefixes.
  - Symmetrical clipboard bindings accommodate both Helix operator-style and Vim leader-style muscle memory while preserving native register access.
  - Arch: Module Seams

### Framework

- [x] D30 [R06]: Enable PipeWire with ALSA, 32-bit ALSA, and PulseAudio compatibility.
  - Alternatives: raw ALSA only.
  - Consequences: `roles/desktop/system/services.nix` owns the audio stack.
  - Modern and legacy applications share one low-latency server.
  - Arch: Framework & Library Choices

- [x] D20 [R08]: Use the current Home Manager visual baseline: styles, GTK/Qt theme, cursor, icons, Hyprland appearance, and Noctalia.
  - Alternatives: start with app bundles or touch gestures.
  - Consequences: apps, touch, and HDR followed as separate slices.
  - The visual baseline gives the desktop identity before app expansion.
  - Arch: Framework & Library Choices

- [x] D49 [R18]: Scope `/retro` to the active session context with emission to `artifacts/retro.md`.
  - Alternatives: automatic post-task triggers, or mixing scope drift reconciliation into retro.
  - Consequences: `/retro` focuses strictly on efficiency, errors, winning patterns, and rule compliance; alignment reconciliation stays in `/update`.
  - Keeping retrospective analysis separate from artifact reconciliation prevents conflating task delivery with execution critique.
  - Arch: Framework & Library Choices

- [x] D50 [R19]: Introduce corpus-audit skill focused on thinking loops and harness rule synthesis.
  - Alternatives: overload single-session retro, or expand session-audit without multi-session compaction.
  - Consequences: `corpus-audit` processes multiple compacted session logs across harnesses; findings feed directly into `author-harness` and rule sets.
  - Separate intra-session reflection from multi-session meta-evaluation across agent lifecycles.
  - Arch: Framework & Library Choices

- [x] D51 [R20]: Decompose Neovim configuration into domain modules co-locating lazy plugins, options, and keymaps.
  - Alternatives: maintain the monolithic 940-line `keymaps.nix` and central `core.nix` plugin dictionary.
  - Consequences: `quickfix.nix`, `preview.nix`, `editing.nix` encapsulate their respective packages, whichKey registrations, and keymaps; `core.nix` retains only editor core/primitives and `keymaps.nix` retains global leader/operator tables.
  - Co-locating configuration with keybindings eliminates orphan mappings and keeps domain concerns modular.
  - Arch: Framework & Library Choices

- [x] D54 [R19]: Consolidate frontend micro-skills into `ui-author` and `ui-audit` umbrella skills.
  - Alternatives: maintain 6 discrete micro-skills (`a11y-interaction-audit`, `design-tokens-audit`, `layout-audit`, `ui-state-model`, `headless-primitive-author`, `motion-choreography`) or introduce custom specialist subagents.
  - Consequences: `ui-author` unifies headless primitives, async state machines, and compositor motion for `engineer` and `worker`; `ui-audit` unifies accessibility, layout density, and design token checks for `code-reviewer`. Superseded by review absorption; both lenses now live in `assets/skills/review/references/ui.md`.
  - Replaces 6 granular schema entries with 2 cohesive umbrella skills, reducing prompt bloat while preserving full frontend authoring and auditing capabilities without specialist subagents.
  - Arch: Framework & Library Choices

- [x] D55 [R19]: Full-stack backend and architecture umbrella skills (`backend-author` and `modular-design`).
  - Alternatives: maintain granular database/API micro-skills, or create specialist backend subagents.
  - Consequences: `backend-author` governs transport boundary validation, thin controllers, pure domain services, standardized RFC 9457 errors, and timeout budgets for `engineer` and `worker`; `modular-design` governs vertical domain slices, deep modules, inverted ports & adapters seams, and explicit composition roots across `architect`, `engineer`, and `worker`. Superseded by review absorption; backend guidance now lives in `assets/skills/review/references/backend.md`, while `modular-design` remains standalone.
  - Provides comprehensive full-stack and architectural design discipline without specialist subagents or excessive prompt XML bloat.
  - Arch: Framework & Library Choices

- [x] D56 [R19]: Harness model routing and reasoning effort alignment.
  - Alternatives: retain dummy Copilot models in `ai.tiers` and legacy Minimax fallbacks in Kiro.
  - Consequences: Codex settings and agents declare `model = "gpt-6-luna"` with `model_reasoning_effort = "xhigh"`; Kiro agents declare `claude-sonnet-5.5` at effort `low` for high tier (`architect`) and `claude-haiku-5.5` at effort `xhigh` for medium/low tiers; global `ai.tiers` default centralizes on `opencode-go` (`deepseek-v4.1-flash` and `beam-free`).
  - Arch: Framework & Library Choices

- [x] D58 [R08]: Declarative XDG user directories and Wallust template unification.
  - Alternatives: unmanaged user directories and hardcoded `~/.config/wallust/templates`.
  - Consequences: `xdg.userDirs` maps clean user paths and redirects unwanted standard directories (`desktop`, `templates`, `publicShare`) into `~/.local/share/`; Wallust templates deploy into `${config.xdg.userDirs.templates}` (`~/.local/share/templates`) and mirror to `~/.config/wallust/templates`; Noctalia passes `--templates-dir` directly.
  - Ensures a clean `$HOME` without unused clutter directories while unifying template assets across tools.
  - Arch: Framework & Library Choices

- [x] D61 [R23]: Import `github:can1357/oh-my-pi` flake input and bind `programs.omp` via `home/modules/programs/omp.nix`.
  - Alternatives: install via curl installer imperatively, or write a bespoke derivation from source without the upstream flake.
  - Consequences: `inputs.omp.homeManagerModules.default` provides `programs.omp`; `home/modules/programs/omp.nix` wires shared skills, disciplines, rules, agents, and hooks into `~/.omp/agent/`.
  - Provides declarative, hermetic integration with the upstream cached binary and full `ai.*` abstraction bindings.
  - Arch: Framework & Library Choices

- [x] D62 [R24]: Exclude Pi built-in extensions via `programs.pi-coding-agent.settings.extensions` overrides.
  - Alternatives: pass `--no-mcp` or tool flags in CLI wrapper which leaves `tool-search` and `llama.cpp` active.
  - Consequences: `settings.extensions` declares `["-builtin:tool-search" "-builtin:mcp" "-builtin:llama.cpp"]`, which Pi's `DefaultPackageManager` applies during startup and reload to deactivate those extension factories and tools.
  - Keeps extension configuration declarative and hermetic in Home Manager.
  - Arch: Framework & Library Choices

- [x] D63 [R25]: Direct wallpaper Hook orchestration and Wallust Hyprland border template.
  - Alternatives: maintain Noctalia `theme.templates.user` stub templates for triggering individual post-hooks.
  - Consequences: Noctalia `wallpaper_changed` hook directly invokes `wallust run`, computes primary color, and drives `mactahoe-gtk-accent`, `mactahoe-icon-accent --apply`, OpenRGB, and `hyprctl reload`; the builtin `hyprland` template owns `~/.config/hypr/noctalia.lua`; Hyprland consumes its `m.colors` and calls `apply_theme`; `mactahoe-icon-accent` updates `dconf`, `gsettings`, and GTK `settings.ini` files unconditionally.
  - Arch: Framework & Library Choices

- [x] D64 [R26]: Deploy `diagram.nvim` and `image.nvim` with Kitty protocol and bundled CLI tools in Neovim.
  - Alternatives: ASCII diagramming (venn.nvim) or external browser preview extensions.
  - Consequences: `diagram.nvim` renders Mermaid, PlantUML, D2, and Graphviz inline; `image.nvim` renders images via Ghostty's Kitty graphics protocol with `magick_cli`; CLI packages (`imagemagick`, `mermaid-cli`, `plantuml`, `d2`, `graphviz`) are provided in `programs.nvf.settings.vim.extraPackages`; `"diagram.nvim"` added to `allowUnfreePredicate`.
  - Arch: Framework & Library Choices

### Data

- [x] D53 [R19]: Universal harness rules with eager/lazy skill partitioning.
  - Alternatives: dump framework-specific commands (deno, svelte) into global rules, or keep domain UI skills eagerly loaded on all primary agents.
  - Consequences: `rules.nix` encodes 6 universal clamps (declared runner check, exact verify, gate integrity, experiment timebox, subagent caps, primary agent user handoff); primary `engineer` sheds 7 domain skills to cut eager XML prompt bloat by ~50%, delegating UI work to `worker` and UI audits to `code-reviewer`.
  - Negative constraints and circuit breakers must be eager in system prompt; primary agents never invoke other primary agents and halt upon slice completion.
  - Arch: Data & Contracts

- [x] D19 [R06]: Keep Vaultwarden's admin token in `vaultwarden_env` under sops, owned by `vaultwarden` with mode 0400.
  - Alternatives: a plaintext token in the config or no admin panel.
  - Consequences: the token is retrievable with `sops decrypt --extract`.
  - The admin panel stays enabled without exposing the token in git.
  - Arch: Data & Contracts

- [ ] D23 [R13]: Store user password hashes and SSH keys in sops and disable mutable users.
  - Alternatives: keep `passwd` and manual `authorized_keys`.
  - Consequences: `hashedPasswordFile` and `openssh.authorizedKeys` come from secrets.
  - Declarative identity removes imperative account drift.
  - Arch: Data & Contracts

- [x] D32 [R06]: Use NetworkManager with the iwd backend and sops-backed Wi-Fi profiles.
  - Alternatives: wpa_supplicant or imperative connections.
  - Consequences: `hardware/wifi.nix` owns profiles and `wireless_env`.
  - Credentials stay encrypted while profiles remain declarative.
  - Arch: Data & Contracts

- [x] D57 [R19]: Dynamic Bitwarden/rbw key delivery for AI harnesses.
  - Alternatives: store plaintext API keys in dotfiles, or require manual shell exports.
  - Consequences: `zsh.nix` exports `OPENCODE_API_KEY` and `OPENCODE_GO_API_KEY` on startup and via `preexec` hook before AI harness executions; `opencode.nix` explicitly queries environment variables; `pi-coding-agent.nix` declares `auth.json` with dynamic `!rbw get` execution; `ai-hooks.nix` guards `session-start` against non-git home directory scans.
  - Arch: Data & Contracts

### Operations

- [x] D08 [R06]: Keep Headscale, Vaultwarden, Caddy, and ddclient on lacuna.
  - Alternatives: move the services to acervus now.
  - Consequences: lacuna imports `roles/server/system`; acervus stays headless.
  - Avoids a premature Vaultwarden migration while keeping one active server.
  - Arch: Operations & Security

- [x] D09 [R06]: Use Caddy internal TLS for loopback Headscale and Vaultwarden, and trust that CA in `tailscaled`.
  - Alternatives: public ACME with port forwarding, or DNS-01 now.
  - Consequences: browsers and clients must trust the Caddy root CA.
  - Loopback hostnames cannot satisfy public ACME; internal TLS matches the access model.
  - Arch: Operations & Security

- [x] D10 [R06]: Rekey `secrets.yaml` to lacuna's SSH-derived age key and keep the admin PGP key for recovery.
  - Alternatives: keep the old age recipient, or use agenix.
  - Consequences: `sops.useSystemdActivation` installs secrets from a systemd unit; secrets stay encrypted in git.
  - The host key is the only key guaranteed to exist during activation, and systemd activation avoids deprecated activation-script restarts.
  - Arch: Operations & Security

- [ ] D22 [R12]: Use DuckDNS DNS-01 for publicly trusted Caddy certificates when mesh clients need them.
  - Alternatives: forward ports 80/443 for HTTP-01, or keep internal TLS.
  - Consequences: Caddy needs the DuckDNS plugin and API token from sops.
  - DNS-01 avoids public port exposure while providing trusted certs.
  - Arch: Operations & Security

- [x] D28 [R05]: Sign GRUB and kernels with sbctl in Secure Boot install hooks.
  - Alternatives: leave Secure Boot disabled.
  - Consequences: `boot/secure-boot.nix` owns install commands and TPM module args.
  - Secure Boot authenticates the boot chain.
  - Arch: Operations & Security

- [x] D31 [R06]: Route DNS through systemd-resolved with Cloudflare DNS-over-TLS.
  - Alternatives: plain DNS or unencrypted fallback.
  - Consequences: `modules/services/network-services.nix` owns resolvers.
  - DNS traffic is encrypted against ISP inspection.
  - Arch: Operations & Security

- [x] D33 [R06]: Enable udisks2, gvfs, and usbmuxd for removable media and iOS devices.
  - Alternatives: manual mounts.
  - Consequences: `roles/desktop/system/services.nix` owns the daemons.
  - Desktop file managers and mobile devices work without root.
  - Arch: Operations & Security

- [x] D38 [R06]: Trust the nix-community, nix-on-droid, and hyprland Cachix substituters.
  - Alternatives: cache.nixos.org only.
  - Consequences: Termux proot and Hyprland builds can be substituted.
  - Shared caches reduce local builds without changing package content.
  - Arch: Operations & Security

- [x] D39 [R06]: Keep server ingress ports with the Headscale role config.
  - Alternatives: open ports from a generic networking module.
  - Consequences: `roles/server/system` owns 80/443 and 3478.
  - Lacuna as a client opens no server ports outside the role.
  - Arch: Operations & Security

- [x] D40 [R05]: Enable monthly BTRFS scrub, zram, and explicit mount options.
  - Alternatives: no scrub and default mount flags.
  - Consequences: `hardware/filesystems.nix` owns scrub, zram, and mount policy.
  - Regular scrubs detect bitrot while zram reduces swap pressure.
  - Arch: Operations & Security

## Non-Goals
- Automated backup and restore for Vaultwarden, Headscale, Caddy state, or home data; rclone safety is the only sync change in this backlog.
- UKI/lanzaboote initrd signing, measured boot, and TPM PCR policy changes.
- Ephemeral root and Impermanence bind mounts.
- WebAuthn/biometric PAM challenges.
- Nvidia or hybrid graphics on lacuna.
- WSL hosts, AMD GPU support, systemd-boot.
- Battery charge thresholds on acervus.
- Public ACME on loopback-only hostnames.
- Rebuilding OMP Rust and Bun compiler stack from source when cached upstream flake binaries exist.
