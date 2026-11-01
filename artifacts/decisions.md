# Architectural Decisions

### System Shape

- [x] D01 [R01]: Use Layout A class-separated trees and merge Home Manager into `home/`.
  - Context: One evaluation keeps the system and user layers reviewable together.
  - Alternatives: a full dendritic flake, or an external Home Manager repository.
  - Consequences: `home/modules/{ai,core,environment,programs,services,shell,styles}` share one lockfile.

- [x] D02 [R02]: Keep release-26.05 as the primary nixpkgs, with `pkgs.unstable`, the kernel, Home Manager, and user programs on unstable.
  - Context: Stable drivers avoid regressions while desktop programs track current nixpkgs.
  - Alternatives: unstable primary with stable hardware, or all-stable.
  - Consequences: standalone Home Manager uses unstable packages; NixOS stays stable.

- [x] D03 [R03]: Hosts import one chassis profile, role modules, and explicit hardware and boot traits.
  - Context: Imports express chassis, duty, and capability without `config.profile` checks.
  - Alternatives: per-host conditionals or fused profile+role bundles.
  - Consequences: `hosts/<name>/default.nix` stays a short composition list.

- [x] D04 [R04]: Treat touch and HDR as hardware traits that bridge into Home Manager.
  - Context: Hardware capabilities gate compositor behavior without host-specific branches.
  - Alternatives: duplicate host checks in compositor modules.
  - Consequences: standalone Home Manager sets both flags for lacuna; hardware traits record host capability.

- [x] D05 [R04]: Lacuna is Intel Arc only; acervus uses hybrid Intel + Nvidia PRIME.
  - Context: Matches the actual PCI hardware while keeping lacuna's driver surface minimal.
  - Alternatives: one graphics trait for both hosts.
  - Consequences: acervus imports `hardware/hybrid-gpu.nix`; lacuna does not.

- [x] D06 [R05]: Split boot integration into `boot/{kernel,grub,tpm,secure-boot,minegrub,plymouth}.nix`.
  - Context: Platform integration stays separate from hardware capabilities.
  - Alternatives: one `boot.nix`, or systemd-boot.
  - Consequences: hosts import only the boot components they need.

- [x] D07 [R05]: Use Disko with GPT, LUKS, and BTRFS subvolumes for lacuna.
  - Context: Declarative encryption and subvolumes make recovery and rollback auditable.
  - Alternatives: imperative partitioning or a single ext4 root.
  - Consequences: the host owns `disko.nix`; acervus keeps a placeholder until install.

- [x] D11 [R07]: Keep Hyprland, UWSM, and the Noctalia greeter system-managed while Home Manager owns the user session.
  - Context: The login path remains stable while user configuration iterates.
  - Alternatives: let Home Manager install the compositor and portal.
  - Consequences: Home Manager sets `package = null` and `portalPackage = null`.

- [x] D14 [R09]: Expose `nixOnDroidConfigurations.fovea` from a root nix-on-droid config on unstable aarch64.
  - Context: Termux needs a standalone profile, not NixOS boot or hardware modules.
  - Alternatives: a `hosts/fovea` NixOS directory, or no Termux output.
  - Consequences: Termux stays outside NixOS host enumeration.

- [x] D18 [R05]: Run acervus as a headless laptop with lid close ignored and suspend disabled; no charge threshold.
  - Context: The server stays reachable when the lid closes, without unwanted battery caps.
  - Alternatives: desktop power policy on the server, or battery caps.
  - Consequences: power policy lives in the acervus host module.

- [x] D25 [R05]: Use a 3-second GRUB timeout and a matching Minegrub main-menu timeout.
  - Context: Users get enough time to pick a generation without a long wait.
  - Alternatives: keep the packaged 15-second timeout.
  - Consequences: `boot.loader.timeout` and the theme config agree.

- [x] D26 [R04]: Include i915 early KMS and `i915.fastboot=1` in the Intel graphics trait.
  - Context: Early KMS avoids the black-screen handoff into Plymouth and the greeter.
  - Alternatives: late KMS with panel reinitialization.
  - Consequences: `hardware/graphics.nix` owns the kernel module and parameter.

- [x] D27 [R05]: Use systemd initrd with TPM2 unlock and PCR measurement.
  - Context: TPM-bound unlock avoids retyping the passphrase on the trusted host.
  - Alternatives: passphrase-only initrd.
  - Consequences: `boot/tpm.nix` owns crypttab options, `tpm_tis`, and PCR phases.

- [x] D29 [R05]: Keep Minegrub packages in `pkgs/` and theme selection in `boot/minegrub.nix`.
  - Context: Only lacuna imports the theme.
  - Alternatives: a hardware minegrub module.
  - Consequences: package declarations stay separate from boot aesthetics.

- [x] D34 [R05]: Keep laptop thermal and power policy in `profiles/laptop/default.nix`.
  - Context: Chassis policy stays separate from capability.
  - Alternatives: hardware traits owning thermald and upower.
  - Consequences: the profile enables thermald, upower, and power-profiles-daemon.

### Module Seams

- [x] D13 [R08]: Define a neutral verb-object shortcut catalog and render it in Hyprland.
  - Context: One catalog can later feed Niri or another compositor.
  - Alternatives: hardcode every keybind in the compositor module.
  - Consequences: compositor modules map action names to native dispatchers.

- [x] D12 [R08]: Split `home/cli.nix` for shared options from `home/gui.nix` for the compositor and visual tier.
  - Context: Superseded by D46's recursive import-tree layout.
  - Alternatives: one monolithic Home Manager tree.
  - Consequences: CLI-only hosts can import the baseline without GUI modules.

- [x] D15 [R10]: Enforce structural invariants with flake checks.
  - Context: Shell checks catch accidental profile, role, boot, and Home Manager drift.
  - Alternatives: prose-only specs.
  - Consequences: layout drift fails `nix flake check`.

- [x] D41 [R15]: Keep domain checks under `tests/` with a recursive loader and one derivation per domain.
  - Context: Splitting by domain isolates failures and keeps flake composition small.
  - Alternatives: one large inline `runCommand` in `flake/default.nix`.
  - Consequences: `tests/default.nix` maps each file to `checks.x86_64-linux.<name>`.

- [x] D42 [R16]: Port the shell and terminal toolset before adding GUI app bundles or prompt theming.
  - Context: A CLI-only host must be useful without a compositor or theme generator.
  - Alternatives: keep every Home Manager module in one tree.
  - Consequences: zsh, zoxide, git, direnv, tealdeer, and core tools live under `home/modules/terminal`; they have no GUI dependency. D60 later split terminal, CLI, and program modules.

- [x] D43 [R17]: Port remaining Home Manager modules in functional slices and mark parity only after each slice evaluates.
  - Context: Most sibling modules are still absent; the current completed tasks cover infrastructure and the visual baseline only.
  - Alternatives: copy every module at once.
  - Consequences: prompt theming, GUI apps, editor/AI, and auxiliary services land independently.

- [x] D16 [R02]: Expose `unfreePackages` as a declarable list merged into `allowUnfreePredicate`.
  - Context: Package licensing becomes explicit at the module boundary.
  - Alternatives: one hardcoded unfree list.
  - Consequences: owning modules append the names they need.

- [x] D17 [R03]: Compose `users.adminExtraGroups` into every admin and let owning modules append their group.
  - Context: Hosts that omit a module do not receive stale group memberships.
  - Alternatives: hardcode every group in `modules/system/users.nix`.
  - Consequences: Podman, Wi-Fi, RGB, TPM, and graphics modules own their groups.

- [x] D21 [R11]: Split optional apps into `home/modules/programs/gaming` and keep PrismLauncher out of the CLI baseline.
  - Context: Optional apps must not expand CLI-only hosts.
  - Alternatives: install every GUI app globally.
  - Consequences: gaming apps are explicit host or role imports.

- [x] D35 [R01]: Keep recursive module discovery in `lib/default.nix`.
  - Context: New modules are picked up without loader boilerplate.
  - Alternatives: manual imports in every directory.
  - Consequences: `modules/default.nix` uses `mkModuleLoader`.

- [x] D36 [R01]: Keep the package overlay in `pkgs/default.nix` with directory camelCasing.
  - Context: Local packages are exposed without editing an index.
  - Alternatives: a hardcoded package list.
  - Consequences: file names stay kebab-case; directory scopes become camelCase.

- [x] D37 [R01]: Keep language devShells in `flake/devshells.nix` on unstable.
  - Context: Toolchains remain isolated per project.
  - Alternatives: global toolchain installs.
  - Consequences: shells stay flake-local and are not host packages.

- [x] D44 [R08]: Organize Home Manager implementation modules by domain under `home/modules/{ai,core,environment,programs,services,shell,styles}`.
  - Context: Superseded entrypoint details by D46.
  - Alternatives: tier directories under `home/modules/{cli,gui,apps}`, or a flat module tree.
  - Consequences: domain modules load without a central file list.

- [x] D45 [R08]: Name per-user Home Manager entrypoints after the account and discover them from `home/*.nix`.
  - Context: User files express identity while shared domain modules stay reusable.
  - Alternatives: one generic `home.nix` with inline user identity, or a hardcoded user list in the flake.
  - Consequences: `home/hollowheap.nix` owns identity and imports; a future `home/steve.nix` is discovered automatically.

- [x] D46 [R08]: Load Home Manager modules recursively with `import-tree` and centralize shared desktop values in `modules/options/desktop.nix`.
  - Context: Modules own their options and wiring; only genuinely shared data is centralized.
  - Alternatives: explicit `home/cli.nix` and `home/gui.nix` import lists, or duplicated Hyprland and greeter values.
  - Consequences: no central module list; Hyprland and the greeter read the same monitors, primary output, scale, and fonts.

- [x] D47 [R08]: Keep Hyprland binds and submaps in `home/modules/programs/hyprland/keybinds.nix`, with shared Lua helpers in `home/lib/hyprland.nix`.
  - Context: Shared interaction policy without a centralized host list.
  - Alternatives: duplicate the bind table in each host's compositor module.
  - Consequences: any Home Manager configuration using `import-tree` gets the same keybinds; host-specific compositor settings stay separate.

- [x] D48 [R08]: Keep compositor window dimensions in `home/modules/environment/compositor.nix` under `desktop.compositor`.
  - Context: Compositor geometry is not a theme token or a program-specific setting.
  - Alternatives: keep dimensions under `styles.dims` or Hyprland-specific options.
  - Consequences: Hyprland and Noctalia consume the same gaps, borders, radius, and bar height.

- [x] D59 [R21]: Vertical domain slices for server role daemons.
  - Context: Enables open-closed extensibility where adding or modifying a service touches only its dedicated slice without mutating the reverse proxy monolith.
  - Alternatives: maintain monolithic `roles/server/system/default.nix` with hardcoded reverse proxy ports and secrets.
  - Consequences: `roles/server/system/` decomposes into `caddy.nix`, `headscale.nix`, `vaultwarden.nix`, and `ddclient.nix`, tied together by `default.nix`; each service declares its own `services.caddy.virtualHosts` block, ports, and restart units.

- [x] D60 [R22]: Decoupled home module taxonomy across terminal, cli, and programs.
  - Context: Creates clear cohesion boundaries matching process lifecycle and user interaction model while leaving `import-tree` auto-discovery intact.
  - Alternatives: mix interactive shells, headless utilities, and GUI/AI apps inside a bloated `home/modules/programs/`.
  - Consequences: `home/modules/terminal` holds shell runtime, prompts, and multiplexers (`zsh`, `starship`, `tmux`, `zoxide`, `direnv`); `home/modules/cli` holds standalone headless utilities (`git`, `lazygit`, `bat`, `btop`, `yazi`, `fastfetch`, `tealdeer`, `gpg`, `ssh`); `home/modules/programs` retains complex desktop suites, editors, and AI harnesses.

- [x] D24 [R14]: Add long-press, multi-finger, and edge gestures to the touch compositor module.
  - Context: Touch navigation should cover common window management without a keyboard.
  - Alternatives: keep only workspace swipe and the on-screen keyboard bind.
  - Consequences: gestures map to window, launcher, and workspace actions.

- [x] D52 [R20]: Dual clipboard yank mappings (`ry` and `<leader>y`) with native register access.
  - Context: Symmetrical clipboard bindings accommodate both Helix operator-style and Vim leader-style muscle memory while preserving native register access.
  - Alternatives: restrict clipboard yank exclusively to `ry` operator or `<leader>y` leader map; keep `"` cleared.
  - Consequences: both `ry` and `<leader>y` (with `yy` and `Y` variants) yank to system clipboard (`"+y`), restoring symmetry with `<leader>p`/`<leader>P`; removing `"` from `<Nop>` clears restores native register prefixes.

### Framework & Library Choices

- [x] D30 [R06]: Enable PipeWire with ALSA, 32-bit ALSA, and PulseAudio compatibility.
  - Context: Modern and legacy applications share one low-latency server.
  - Alternatives: raw ALSA only.
  - Consequences: `roles/desktop/system/services.nix` owns the audio stack.

- [x] D20 [R08]: Use the current Home Manager visual baseline: styles, GTK/Qt theme, cursor, icons, Hyprland appearance, and Noctalia.
  - Context: The visual baseline gives the desktop identity before app expansion.
  - Alternatives: start with app bundles or touch gestures.
  - Consequences: apps, touch, and HDR followed as separate slices.

- [x] D49 [R18]: Scope `/retro` to the active session context with emission to `artifacts/retro.md`.
  - Context: Keeping retrospective analysis separate from artifact reconciliation prevents conflating task delivery with execution critique.
  - Alternatives: automatic post-task triggers, or mixing scope drift reconciliation into retro.
  - Consequences: `/retro` focuses strictly on efficiency, errors, winning patterns, and rule compliance; alignment reconciliation stays in `/update`.

- [x] D50 [R19]: Introduce corpus-audit skill focused on thinking loops and harness rule synthesis.
  - Context: Separate intra-session reflection from multi-session meta-evaluation across agent lifecycles.
  - Alternatives: overload single-session retro, or expand session-audit without multi-session compaction.
  - Consequences: `corpus-audit` processes multiple compacted session logs across harnesses; findings feed directly into `author-harness` and rule sets.

- [x] D51 [R20]: Decompose Neovim configuration into domain modules co-locating lazy plugins, options, and keymaps.
  - Context: Co-locating configuration with keybindings eliminates orphan mappings and keeps domain concerns modular.
  - Alternatives: maintain the monolithic 940-line `keymaps.nix` and central `core.nix` plugin dictionary.
  - Consequences: `quickfix.nix`, `preview.nix`, `editing.nix` encapsulate their respective packages, whichKey registrations, and keymaps; `core.nix` retains only editor core/primitives and `keymaps.nix` retains global leader/operator tables.

- [x] D54 [R19]: Consolidate frontend micro-skills into `ui-author` and `ui-audit` umbrella skills.
  - Context: Replaces 6 granular schema entries with 2 cohesive umbrella skills, reducing prompt bloat while preserving full frontend authoring and auditing capabilities without specialist subagents.
  - Alternatives: maintain 6 discrete micro-skills (`a11y-interaction-audit`, `design-tokens-audit`, `layout-audit`, `ui-state-model`, `headless-primitive-author`, `motion-choreography`) or introduce custom specialist subagents.
  - Consequences: `ui-author` unifies headless primitives, async state machines, and compositor motion for `engineer` and `worker`; `ui-audit` unifies accessibility, layout density, and design token checks for `code-reviewer`. Superseded by review absorption; both lenses now live in `assets/skills/review/references/ui.md`.

- [x] D55 [R19]: Full-stack backend and architecture umbrella skills (`backend-author` and `modular-design`).
  - Context: Provides comprehensive full-stack and architectural design discipline without specialist subagents or excessive prompt XML bloat.
  - Alternatives: maintain granular database/API micro-skills, or create specialist backend subagents.
  - Consequences: `backend-author` governs transport boundary validation, thin controllers, pure domain services, standardized RFC 9457 errors, and timeout budgets for `engineer` and `worker`; `modular-design` governs vertical domain slices, deep modules, inverted ports & adapters seams, and explicit composition roots across `architect`, `engineer`, and `worker`. Superseded by review absorption; backend guidance now lives in `assets/skills/review/references/backend.md`, while `modular-design` remains standalone.

- [x] D56 [R19]: Harness model routing and reasoning effort alignment.
  - Context: none
  - Alternatives: retain dummy Copilot models in `ai.tiers` and legacy Minimax fallbacks in Kiro.
  - Consequences: Codex settings and agents declare `model = "gpt-6-luna"` with `model_reasoning_effort = "xhigh"`; Kiro agents declare `claude-sonnet-5.5` at effort `low` for high tier (`architect`) and `claude-haiku-5.5` at effort `xhigh` for medium/low tiers; global `ai.tiers` default centralizes on `opencode-go` (`deepseek-v4.1-flash` and `beam-free`).

- [x] D58 [R08]: Declarative XDG user directories and Wallust template unification.
  - Context: Ensures a clean `$HOME` without unused clutter directories while unifying template assets across tools.
  - Alternatives: unmanaged user directories and hardcoded `~/.config/wallust/templates`.
  - Consequences: `xdg.userDirs` maps clean user paths and redirects unwanted standard directories (`desktop`, `templates`, `publicShare`) into `~/.local/share/`; Wallust templates deploy into `${config.xdg.userDirs.templates}` (`~/.local/share/templates`) and mirror to `~/.config/wallust/templates`; Noctalia passes `--templates-dir` directly.

- [x] D61 [R23]: Import `github:can1357/oh-my-pi` flake input and bind `programs.omp` via `home/modules/programs/omp.nix`.
  - Context: Provides declarative, hermetic integration with the upstream cached binary and full `ai.*` abstraction bindings.
  - Alternatives: install via curl installer imperatively, or write a bespoke derivation from source without the upstream flake.
  - Consequences: `inputs.omp.homeManagerModules.default` provides `programs.omp`; `home/modules/programs/omp.nix` wires shared skills, disciplines, rules, agents, and hooks into `~/.omp/agent/`.

- [x] D62 [R24]: Exclude Pi built-in extensions via `programs.pi-coding-agent.settings.extensions` overrides.
  - Context: Keeps extension configuration declarative and hermetic in Home Manager.
  - Alternatives: pass `--no-mcp` or tool flags in CLI wrapper which leaves `tool-search` and `llama.cpp` active.
  - Consequences: `settings.extensions` declares `["-builtin:tool-search" "-builtin:mcp" "-builtin:llama.cpp"]`, which Pi's `DefaultPackageManager` applies during startup and reload to deactivate those extension factories and tools.

- [x] D63 [R25]: Direct wallpaper Hook orchestration and Wallust Hyprland border template.
  - Context: none
  - Alternatives: maintain Noctalia `theme.templates.user` stub templates for triggering individual post-hooks.
  - Consequences: Noctalia `wallpaper_changed` hook directly invokes `wallust run`, computes primary color, and drives `mactahoe-gtk-accent`, `mactahoe-icon-accent --apply`, OpenRGB, and `hyprctl reload`; the builtin `hyprland` template owns `~/.config/hypr/noctalia.lua`; Hyprland consumes its `m.colors` and calls `apply_theme`; `mactahoe-icon-accent` updates `dconf`, `gsettings`, and GTK `settings.ini` files unconditionally.

- [x] D64 [R26]: Deploy `diagram.nvim` and `image.nvim` with Kitty protocol and bundled CLI tools in Neovim.
  - Context: none
  - Alternatives: ASCII diagramming (venn.nvim) or external browser preview extensions.
  - Consequences: `diagram.nvim` renders Mermaid, PlantUML, D2, and Graphviz inline; `image.nvim` renders images via Ghostty's Kitty graphics protocol with `magick_cli`; CLI packages (`imagemagick`, `mermaid-cli`, `plantuml`, `d2`, `graphviz`) are provided in `programs.nvf.settings.vim.extraPackages`; `"diagram.nvim"` added to `allowUnfreePredicate`.

### Data & Contracts

- [x] D53 [R19]: Universal harness rules with eager/lazy skill partitioning.
  - Context: Negative constraints and circuit breakers must be eager in system prompt; primary agents never invoke other primary agents and halt upon slice completion.
  - Alternatives: dump framework-specific commands (deno, svelte) into global rules, or keep domain UI skills eagerly loaded on all primary agents.
  - Consequences: `rules.nix` encodes 6 universal clamps (declared runner check, exact verify, gate integrity, experiment timebox, subagent caps, primary agent user handoff); primary `engineer` sheds 7 domain skills to cut eager XML prompt bloat by ~50%, delegating UI work to `worker` and UI audits to `code-reviewer`.

- [x] D19 [R06]: Keep Vaultwarden's admin token in `vaultwarden_env` under sops, owned by `vaultwarden` with mode 0400.
  - Context: The admin panel stays enabled without exposing the token in git.
  - Alternatives: a plaintext token in the config or no admin panel.
  - Consequences: the token is retrievable with `sops decrypt --extract`.

- [ ] D23 [R13]: Store user password hashes and SSH keys in sops and disable mutable users.
  - Context: Declarative identity removes imperative account drift.
  - Alternatives: keep `passwd` and manual `authorized_keys`.
  - Consequences: `hashedPasswordFile` and `openssh.authorizedKeys` come from secrets.

- [x] D32 [R06]: Use NetworkManager with the iwd backend and sops-backed Wi-Fi profiles.
  - Context: Credentials stay encrypted while profiles remain declarative.
  - Alternatives: wpa_supplicant or imperative connections.
  - Consequences: `hardware/wifi.nix` owns profiles and `wireless_env`.

- [x] D57 [R19]: Dynamic Bitwarden/rbw key delivery for AI harnesses.
  - Context: none
  - Alternatives: store plaintext API keys in dotfiles, or require manual shell exports.
  - Consequences: `zsh.nix` exports `OPENCODE_API_KEY` and `OPENCODE_GO_API_KEY` on startup and via `preexec` hook before AI harness executions; `opencode.nix` explicitly queries environment variables; `pi-coding-agent.nix` declares `auth.json` with dynamic `!rbw get` execution; `ai-hooks.nix` guards `session-start` against non-git home directory scans.

### Operations & Security

- [x] D08 [R06]: Keep Headscale, Vaultwarden, Caddy, and ddclient on lacuna.
  - Context: Avoids a premature Vaultwarden migration while keeping one active server.
  - Alternatives: move the services to acervus now.
  - Consequences: lacuna imports `roles/server/system`; acervus stays headless.

- [x] D09 [R06]: Use Caddy internal TLS for loopback Headscale and Vaultwarden, and trust that CA in `tailscaled`.
  - Context: Loopback hostnames cannot satisfy public ACME; internal TLS matches the access model.
  - Alternatives: public ACME with port forwarding, or DNS-01 now.
  - Consequences: browsers and clients must trust the Caddy root CA.

- [x] D10 [R06]: Rekey `secrets.yaml` to lacuna's SSH-derived age key and keep the admin PGP key for recovery.
  - Context: The host key is the only key guaranteed to exist during activation, and systemd activation avoids deprecated activation-script restarts.
  - Alternatives: keep the old age recipient, or use agenix.
  - Consequences: `sops.useSystemdActivation` installs secrets from a systemd unit; secrets stay encrypted in git.

- [ ] D22 [R12]: Use DuckDNS DNS-01 for publicly trusted Caddy certificates when mesh clients need them.
  - Context: DNS-01 avoids public port exposure while providing trusted certs.
  - Alternatives: forward ports 80/443 for HTTP-01, or keep internal TLS.
  - Consequences: Caddy needs the DuckDNS plugin and API token from sops.

- [x] D28 [R05]: Sign GRUB and kernels with sbctl in Secure Boot install hooks.
  - Context: Secure Boot authenticates the boot chain.
  - Alternatives: leave Secure Boot disabled.
  - Consequences: `boot/secure-boot.nix` owns install commands and TPM module args.

- [x] D31 [R06]: Route DNS through systemd-resolved with Cloudflare DNS-over-TLS.
  - Context: DNS traffic is encrypted against ISP inspection.
  - Alternatives: plain DNS or unencrypted fallback.
  - Consequences: `modules/services/network-services.nix` owns resolvers.

- [x] D33 [R06]: Enable udisks2, gvfs, and usbmuxd for removable media and iOS devices.
  - Context: Desktop file managers and mobile devices work without root.
  - Alternatives: manual mounts.
  - Consequences: `roles/desktop/system/services.nix` owns the daemons.

- [x] D38 [R06]: Trust the nix-community, nix-on-droid, and hyprland Cachix substituters.
  - Context: Shared caches reduce local builds without changing package content.
  - Alternatives: cache.nixos.org only.
  - Consequences: Termux proot and Hyprland builds can be substituted.

- [x] D39 [R06]: Keep server ingress ports with the Headscale role config.
  - Context: Lacuna as a client opens no server ports outside the role.
  - Alternatives: open ports from a generic networking module.
  - Consequences: `roles/server/system` owns 80/443 and 3478.

- [x] D40 [R05]: Enable monthly BTRFS scrub, zram, and explicit mount options.
  - Context: Regular scrubs detect bitrot while zram reduces swap pressure.
  - Alternatives: no scrub and default mount flags.
  - Consequences: `hardware/filesystems.nix` owns scrub, zram, and mount policy.

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
