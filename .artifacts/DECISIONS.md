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

- [ ] D70 [R56]: Partition `secrets.yaml` into `secrets/common.yaml` (shared host secrets encrypted for `lacuna` and `acervus`) and `secrets/lacuna.yaml` (server secrets encrypted for `lacuna` only).
  - Context: `acervus` imports `hardware/wifi.nix` and `modules/security/sops.nix` expecting `wireless_env`, whereas monolithic `secrets.yaml` only lists `lacuna`'s age recipient and also stores server secrets (`vaultwarden_env`, `duckdns_password`).
  - Alternatives: enroll `acervus` into a monolithic `secrets.yaml` (grants laptop access to server secrets), or drop Wi-Fi secrets on `acervus`.
  - Consequences: `.sops.yaml` declares separate path regex rules per host scope; `modules/security/sops.nix` reads `secrets/common.yaml`, `hosts/lacuna` adds `secrets/lacuna.yaml`, `wireless_env` restarts `NetworkManager-ensure-profiles.service` before `NetworkManager.service`, and dead `caddy_tls_key`/`caddy_ca_key` entries are pruned.
  - Supersedes: D10

- [ ] D71 [R33]: Enforce `HandleLidSwitch = "suspend-then-hibernate"` in laptop power policy, locking instead when Noctalia caffeine inhibitor is active.
  - Context: `profiles/laptop/default.nix` currently hardcodes `HandleLidSwitch = "lock"`, draining battery during transport, while unconditional hibernate breaks active stay-awake downloads and presentations.
  - Alternatives: leave `HandleLidSwitch = "lock"` everywhere, or ignore caffeine state on lid close.
  - Consequences: systemd-logind defaults lid actions to `suspend-then-hibernate`; Noctalia's caffeine inhibitor coordinates with session lock so closing the lid while caffeine is active locks instead of suspending.

- [x] D72 [R27]: Retire `retro`, `corpus-audit`, and `omp`; consolidate coding-agent workflows onto `pi-coding-agent`, `review`, and `update`.
  - Context: `R18` (`retro`), `R19` (`corpus-audit`), and `R23` (`omp`) remained checked despite skill retirement and `omp.nix` removal in favor of lighter `pi-coding-agent`.
  - Alternatives: restore separate `retro`, `corpus-audit`, and `omp` modules.
  - Consequences: `R18`/`R19`/`R23` stay retired without broken eval checks; agent focus consolidates on maintained `pi-coding-agent` and shared skills.
  - Supersedes: D49, D50, D61

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

- [ ] D73 [R08]: Keep `modules/options/desktop.nix` defaults hardware-neutral and place `lacuna` display, Wacom, and Yoga switch overrides in a standalone Home Manager host-trait overlay and `hosts/lacuna/`.
  - Context: `modules/options/desktop.nix` leaks Lacuna's `eDP-1` / `1.25` / `2880x1800@120` defaults onto headless `acervus`, while shared HM modules embed `wacom-hid-53b7-*` and `Lenovo Yoga Tablet Mode Control switch`.
  - Alternatives: couple HM evaluation directly to NixOS host outputs via `extraSpecialArgs`.
  - Consequences: standalone HM evaluation stays independent; `modules/options/desktop.nix` defaults become neutral (`null`/`[]`); `roles/desktop/system/default.nix` consumes `desktop.primaryOutput`, XKB `variant`/`options`, and NixOS UI font packages; `desktop.touchscreen` and `desktop.shortcuts` resolve cleanly without closed throws.

- [ ] D74 [R15]: Consolidate all flake checks inside `tests/`, add extensible `unfreePackages` to Home Manager, and export shared `lib` helpers via `outputs.lib`.
  - Context: `flake/default.nix` inlines ~130 lines of checks hardcoded to `homeConfigurations.hollowheap`, hardcodes HM unfree packages, injects desktop/boot external modules onto all hosts, and forces `../../../lib/` relative path traversal.
  - Alternatives: retain inline checks in `flake/default.nix` and manual per-file unfree predicates.
  - Consequences: `tests/default.nix` accepts evaluated configurations and filtered `lib.fileset` sources, relocates `ai-rendered`/`skills-rendered` out of `flake/default.nix`, moves desktop/boot external imports to their owning roles/modules, and mirrors NixOS `unfreePackages` inside HM.
  - Supersedes: D41

### Framework & Library Choices

- [x] D30 [R06]: Enable PipeWire with ALSA, 32-bit ALSA, and PulseAudio compatibility.
  - Context: Modern and legacy applications share one low-latency server.
  - Alternatives: raw ALSA only.
  - Consequences: `roles/desktop/system/services.nix` owns the audio stack.

- [x] D20 [R08]: Use the current Home Manager visual baseline: styles, GTK/Qt theme, cursor, icons, Hyprland appearance, and Noctalia.
  - Context: The visual baseline gives the desktop identity before app expansion.
  - Alternatives: start with app bundles or touch gestures.
  - Consequences: apps, touch, and HDR followed as separate slices.

- [x] D49 [R18]: Scope `/retro` to the active session context with emission to `.artifacts/RETRO.md`.
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

- [x] D66 [R28]: Render every harness through `agentBodyFor` and `ai.tiers`.
  - Context: Seven renderers send empty instructions, and four hardcode models or effort values.
  - Alternatives: maintain per-harness prompts and model maps.
  - Consequences: `config.ai.render.agentBodyFor` is the only agent-body path; `modelFor` and `effortFor` resolve from `ai.tiers` with `models.<harness>` overrides; adapters own their tier-to-model mapping.
  - Resolves: Q12

- [x] D69 [R16]: Keep tmux keyboard vi copy mode, root `C-p`/`C-n` window switching, and hidden pane titles in `home/modules/terminal/tmux.nix`.
  - Context: Resolves tmux UX questions with keyboard copying prioritized, window navigation keys retained, and status bar focused on window pills.
  - Alternatives: remap window switching to `M-p`/`M-n` or prefix bindings and display per-pane title bars.
  - Consequences: `home/modules/terminal/tmux.nix` retains `bind -n C-p previous-window` / `bind -n C-n next-window`, `copy-mode-vi` `v`/`C-v`/`y` clipboard bindings, and no pane-border title format.
  - Resolves: Q23, Q24, Q25, Q26

- [ ] D75 [R53]: Move root tmux `C-d` popup binding to the prefix table (`prefix d`) to restore shell/REPL EOF while keeping root `C-g`/`C-y`/`C-b`, existing Zsh global aliases, and `D69` `C-p`/`C-n`.
  - Context: Root `bind -n C-d` (`lazydocker`) and `zsh.nix` unbinding `^D` break standard shell and REPL EOF, whereas the user retains quick `C-g`/`C-y`/`C-b` popups and single-letter global aliases.
  - Alternatives: migrate all root popups (`C-d`/`C-g`/`C-y`/`C-b`) to prefix and namespace global aliases (`_D`/`_G`).
  - Consequences: `Ctrl-D` reaches shells/REPLs as EOF again; `C-g`/`C-y`/`C-b` and bare Zsh global aliases remain intentional ergonomics; Zsh cache initialization quotes `${XDG_CACHE_HOME:-$HOME/.cache}` safely and clears `fzf-*-widget` warnings.

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

- [x] D67 [R29]: Make `programs.mcp.servers` the single MCP registry.
  - Context: `capabilities.mcp` gates nothing because no server registry exists.
  - Alternatives: configure MCP separately in each harness or leave the capability inert.
  - Consequences: named stdio servers define command, args, env, and enabled; remote MCP transport is deferred; OpenCode, Codex, Crush, and Copilot render the same registry; agents with `capabilities.mcp` receive access.

- [ ] D76 [R27]: Gate `subagent-io` read-only discipline and rule filtering on `!agent.capabilities.write`, normalize Kiro `.artifacts/*.md` and fail-closed hooks, fix YAML list/paragraph skill parsing, and populate tool matchers.
  - Context: Write-capable `worker` currently receives a read-only mandate; `kiro-cli.nix` targets deleted lowercase `.artifacts/{tasks,specs}.md` and exits `0` on bad JSON; `lib/ai-skills.nix` truncates multi-paragraph YAML blocks and misparses bullet `agents`; `ai.hooks.pre-tool.matcher` is `null`, `efforts.kiro` is inverted, and `hermes.nix` has no enable option.
  - Alternatives: create bespoke per-agent discipline forks outside `ai.disciplines` / `lib/ai-skills.nix`.
  - Consequences: `capabilities.write` cleanly partitions read-only vs write subagents; all `.artifacts/` paths in hooks and Kiro use canonical uppercase filenames; YAML parser handles blank lines in block scalars and bullet lists uniformly.

- [ ] D77 [R29]: Extend `programs.mcp.servers` integration to Kiro, Antigravity, and Hermes while explicitly exempting Pi.
  - Context: 5 of 9 harnesses currently consume `programs.mcp.servers`, leaving Kiro, Antigravity, and Hermes disconnected while Pi explicitly disables `builtin:mcp` per `D62`.
  - Alternatives: restrict `D67` strictly to OpenCode, Claude Code, Codex, Crush, and Copilot.
  - Consequences: all 8 MCP-capable harnesses share `programs.mcp.servers`; Pi remains explicitly exempt via `D62`.
  - Supersedes: D67

- [ ] D78 [R50]: Centralize monochrome neutral ramp constants and contrast rules in `home/modules/styles/palette.nix` while keeping Noctalia M3 and Wallust ANSI-16 bridged through shared activation and hooks.
  - Context: Hand-copied neutral hex codes (`base01`/`base04`/`base06`) drifted across Wallust templates, `pill_load_wallust` read zero lines on newline-less `sequences`, Neovim lacked pre-render `SIGUSR1` registration, `starship` pills hardcoded black text, and `wallustRender` skipped cold starts.
  - Alternatives: drop Wallust completely in favor of Noctalia templates alone.
  - Consequences: one `palette.nix` registry drives shared neutral ramps, contrast-aware pill styling, cold-start preset seeding, EOF-safe `sequences` parsing, and unconditional Neovim `SIGUSR1` signal registration.

- [x] D80 [R19]: Scope OpenCode `rbw` API key injection to per-binary wrappers (`crush`, `opencode`, `pi`) and remove Zsh parent-shell exports.
  - Context: Exporting `OPENCODE_API_KEY` and `OPENCODE_GO_API_KEY` via Zsh startup/`preexec` leaked credentials into every descendant process (`V19`), while `crush.nix` lacked `providers."opencode-go".api_key` and `opencode`/`crush` lacked binary wrappers.
  - Alternatives: migrate `opencode` API key into host `sops-nix`, or retain global Zsh `preexec` exports.
  - Consequences: shared `config.ai.render.wrapWithOpenCodeKey` wraps `crush`, `opencode`, and `pi` with interactive `rbw unlock` fallback (`--folder dev/keys opencode`) scoped to agent child processes; `crush.nix` sets `providers."opencode-go".api_key = "$OPENCODE_API_KEY"`; `pi-coding-agent.nix` drops the read-only `auth.json` symlink so `proper-lockfile` never hits `/nix/store` `EROFS` while `pi` consumes `OPENCODE_API_KEY` from the wrapper; `zsh.nix` drops `_load_ai_keys`, `_ensure_ai_keys_preexec`, and `load-ai-keys`.
  - Supersedes: D57

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

- [x] D65 [R27]: Order permission rules deny-first and enforce capabilities without a `write` key.
  - Context: OpenCode accepts the last matching permission; the current deny-last blocks edits and delegation, and `write` is not a permission key.
  - Alternatives: keep per-agent permission blocks or bypass native permissions with a wrapper.
  - Consequences: OpenCode's permission renderer emits one deny-all rule first, then capability-derived allows; other harnesses map capabilities to native tool lists; `task` allows come from `availableAgents`; architect can edit artifacts and delegate to scout.
  - Resolves: Q11

- [x] D68 [R30]: Make `ai.hooks` the single hook contract and fail closed.
  - Context: Harness hook files reimplement command, matcher, and harness filtering; some are dead and pre-tool failures pass.
  - Alternatives: keep per-harness hook files or fail open for compatibility.
  - Consequences: renderers consume `ai.hooks` event/command/args/matcher/timeout/enabled/harnesses; unsupported event/harness pairs fail at evaluation; malformed pre-tool payloads block the tool.

- [ ] D79 [R12]: Issue ACME TLS certificates via DuckDNS DNS-01 (`caddy-dns/duckdns`) for both public and internal `*.hollowheap.duckdns.org` Caddy vhosts across mobile `lacuna` and future `acervus`.
  - Context: Under `tls internal`, `lacuna` `security.pki.certificateFiles` remained empty and only `tailscaled` overrode `SSL_CERT_FILE`, causing `UnknownIssuer` errors for `rbw sync` and `curl` while not scaling to mobile `lacuna`, Android `fovea`, or server migration to `acervus`.
  - Alternatives: commit Caddy's private root CA into `security.pki.certificateFiles` and distribute manually to Android/clients.
  - Consequences: Caddy obtains trusted Let's Encrypt certs via DuckDNS TXT API calls (no inbound WAN 80/443 needed, cached 90 days offline), removes per-service `SSL_CERT_FILE` point fixes, transfers cleanly when `acervus` becomes the server, and pairs with `acl.hujson` allowing mesh SSH port `22`; public CT logs observe the subdomain names.
  - Supersedes: D09, D22

- [ ] D81 [R30]: Adapt the shared `ai.hooks` contract to harness builtins and drop external hook executions a harness already performs natively.
  - Context: One hook contract currently spawns external commands for git policy and repomap across harnesses, duplicating native capabilities and paying per-tool overhead.
  - Alternatives: keep one uniform external hook invocation for every harness; let each harness hand-maintain its own hooks.
  - Consequences: add a per-harness hook-drop mechanism analogous to `dropDisciplines`/`dropRules`; shared hooks declare intent, adapters omit implementations covered by builtins, and remaining hooks keep one command/matcher/timeout schema.

- [ ] D82 [R29]: Render MCP servers from one shared registry into every harness that supports MCP, including Pi.
  - Context: `programs.mcp.servers` is empty and Pi carries a private hardcoded `mcp.json`; MCP-capable agents receive no tools.
  - Alternatives: per-harness MCP files; keep Pi exempt with a private registry.
  - Consequences: populate the shared registry, gate servers on `capabilities.mcp`, render them in all capable adapters, and remove Pi's private registry file.

- [ ] D83 [R28]: Enable Codex without recompiling it on every rebuild.
  - Context: the adapter is disabled and its `package` override builds vendored aws-lc and extra libraries at evaluation time.
  - Alternatives: leave Codex disabled; accept repeated native compilation on each switch.
  - Consequences: use a prebuilt or cached Codex derivation with the same runtime inputs, then enable the adapter.

- [ ] D84 [R28]: Keep Kiro a neutral adapter; remove `subagentOnly` capability stripping.
  - Context: `kiro-cli.nix` strips `web` and other tools for `role = "subagent"` even though the shared AI schema declares those capabilities.
  - Alternatives: keep harness-specific capability pruning for subagents; change agent roles to satisfy Kiro.
  - Consequences: harnesses render the shared `ai.*` data without harness-specific subagent pruning; capability enforcement stays in the shared schema and non-Kiro adapters.

- [x] D85 [R28]: Drop `ai.tiers`, `modelFor`, and `effortFor`; model and effort selection belong to each harness adapter.
  - Context: model availability and reasoning effort are not harness-agnostic, so a shared abstraction hides real per-harness differences and creates dead tier contracts.
  - Alternatives: keep a shared tier table and per-harness overrides; add the missing `ai.tiers` option.
  - Consequences: delete the shared model/effort helpers and tier table, set model and effort directly in each adapter, and treat model choice as adapter-local policy.

- [x] D86 [R10]: Drop the repomap hook, repomap generator, and all repomap artifacts.
  - Context: `.artifacts/REPOMAP.md` is the canonical path, but the hook writes lowercase `.artifacts/repomap.md` and duplicate maps exist across repositories.
  - Alternatives: keep the hook and fix the path case; keep generated maps as review evidence.
  - Consequences: remove `ai.hooks.session-start`/`post-tool` repomap entries, remove `pkgs/repomap.nix`, delete repomap artifacts under `~/repos/*`, and update docs and checks that reference them.

- [ ] D87 [R15]: Accept every V16 flake discovery and tests finding as valid and fix them.
  - Context: the seam review found unchecked discovered users and hosts, inline checks shadowing `tests/`, missing `outputs.lib`, missing fovea overlay and specialArgs, hardcoded HM unfree policy, static-only assertions, whole-tree check sources, and missing app metadata/package outputs.
  - Alternatives: fix only a subset; defer the seam until a later design pass.
  - Consequences: drive checks from discovered configurations, relocate inline checks, export `lib`, overlay fovea, mirror `unfreePackages` into HM, add evaluation-based assertions, narrow check sources, and register package outputs.

- [ ] D88 [R04]: Enable HDR only on lacuna and consume it on both NixOS and Home Manager layers.
  - Context: `hardware/hdr.nix` declares a setter no host imports; HM never sets `desktop.hdr`, so Hyprland HDR branches are unreachable.
  - Alternatives: enable HDR on all desktops; keep the trait dead.
  - Consequences: lacuna imports the HDR trait, its HM host overlay sets `desktop.hdr = true`, and acervus stays false.

- [ ] D89 [R08]: Move laptop geometry defaults out of shared `desktop.*` options into lacuna host data.
  - Context: `eDP-1`, `1.25`, and `2880x1800@120` leak onto acervus and standalone HM.
  - Alternatives: keep shared fallbacks; null them everywhere.
  - Consequences: shared defaults become neutral, lacuna owns monitor/output values, and HM consumers skip monitors when no host supplies them.

- [ ] D90 [R07]: Derive greeter output, layout, refresh rate, keyboard variant/options, and fonts from shared `desktop.*`.
  - Context: greeter hardcodes `eDP-1` and forwards only `layout`, diverging from the session.
  - Alternatives: keep greeter literals; configure greeter independently.
  - Consequences: greeter and compositor consume the same host-provided desktop contract.

- [ ] D91 [R04]: Treat shell touch and compositor touch as separate abstractions, each consumed by its own layer.
  - Context: one `desktop.touch` setter is duplicated in NixOS and HM with no NixOS consumer.
  - Alternatives: keep one shared boolean for every layer; drop touch configuration entirely.
  - Consequences: desktop shell and compositor each receive touch policy from their own host-scoped abstraction; no orphan NixOS setter.

- [ ] D92 [R33]: Drop the lid/caffeine policy; the Super Caffeine plugin supersedes it.
  - Context: NixOS lid action and Noctalia caffeine coordination are split, and tests assert stale `suspend`.
  - Alternatives: implement logind inhibitor switching; keep the split policy.
  - Consequences: remove lid-action policy and its stale assertion, leaving caffeine handling to the desktop shell plugin.

- [ ] D93 [R39]: Power-saving mode must lower frame rates from actual monitor modes.
  - Context: `replaceStrings "@120" "@60"` silently misses other refresh rates.
  - Alternatives: keep literal substitution; drop power-saving refresh changes.
  - Consequences: parse `<WxH>@<Hz>` and emit a lower Hz value, preserving per-monitor position and scale.

- [ ] D94 [R07]: Install `desktop.fonts` packages on the NixOS side for greeter rendering.
  - Context: fonts are installed only in Home Manager, so the login greeter falls back to generic fonts.
  - Alternatives: keep fonts user-only; hardcode greeter font family.
  - Consequences: the desktop system role installs sans, serif, and monospace packages and sets the greeter font family.

- [ ] D95 [R07]: Drop `desktop.compositor.barHeight`.
  - Context: the option has no consumer in Hyprland, Noctalia, or any adapter.
  - Alternatives: wire it into panel geometry.
  - Consequences: remove the option and any test references.

- [ ] D96 [R07]: Keep `xdg.portal` system-level and use Hyprland's portal for now.
  - Context: portal ownership is absent from `roles/desktop/system`, while rules match a literal portal app id.
  - Alternatives: move portal config to Home Manager; add multiple portals.
  - Consequences: compose the Hyprland portal in the system desktop role and align rules with it.

- [ ] D97 [R10]: Assert every declared Wallust template has a matching asset and check.
  - Context: `starship-palette.toml` is declared but omitted from the template list in `tests/home.nix`.
  - Alternatives: keep hand-maintained lists.
  - Consequences: derive or enumerate all declared templates so a missing asset fails its check.

- [ ] D98 [R08]: Parameterize Wacom and Yoga switch names in host-scoped options.
  - Context: vendor strings are hardcoded in shared `import-tree` modules.
  - Alternatives: keep vendor literals as defaults.
  - Consequences: add `desktop.touchscreen.switchDevice`, set it on lacuna, and render shell/compositor bindings from it.

- [ ] D99 [R52]: Markdown formatting must respect the unified toolchain contract.
  - Context: nvf's Markdown language module installs `deno fmt` into conform despite `formattersByFt.markdown = lib.mkForce [ ]`.
  - Alternatives: accept nvf's default formatter; configure a prose-preserving formatter.
  - Consequences: disable the nvf Markdown format integration so no formatter runs on Markdown saves.

- [ ] D100 [R52]: Drop Neovim session restore.
  - Context: dashboard restore entry relies on `lazy.nvim` while nvf uses `lz.n`, and no restore binding exists.
  - Alternatives: add a `mini.sessions.read()` action and keybinding.
  - Consequences: remove the dead restore entry and session plugin wiring instead of restoring it.

- [ ] D101 [R52]: Keep the Avante `<leader>a*` keymaps; the headless unbound report is not trusted.
  - Context: a headless `maparg` probe reported six unbound keys, but the user confirms they work.
  - Alternatives: delete or rebind the six entries.
  - Consequences: no change to Avante keymaps; future reviews must not treat the headless probe as evidence without a real-session reproduction.

- [ ] D102 [R52]: Register ACP providers for every harness that supports them and remove impure checkout paths.
  - Context: Avante's `pi` provider hardcodes `/home/hollowheap/repos/my-pi-agent/...`; other ACP-capable harnesses are unregistered.
  - Alternatives: keep one provider with a machine-local path.
  - Consequences: derive the provider path from Home Manager or a Nix package and register the confirmed ACP harnesses.

- [ ] D103 [R52]: Register `shfmt` for both `bash` and `zsh` filetypes.
  - Context: conform receives `sh = [ "shfmt" ]` from nvf, but not `bash` or `zsh`.
  - Alternatives: keep the gap and rely on manual formatting.
  - Consequences: add both filetype keys to the unified formatter map.

- [ ] D104 [R50]: The Noctalia `started` hook must derive the wallpaper from persisted settings.
  - Context: `NOCTALIA_WALLPAPER_PATH` exists only on wallpaper change, so editor palettes stay stale after a shell restart.
  - Alternatives: rely on the change event only.
  - Consequences: read the last wallpaper from `settings.toml` on start and apply Wallust templates.

- [ ] D105 [R50]: Preserve distinct base16 syntax roles for readability.
  - Context: the rendered template maps `base09` to the same ANSI slot as `base08`, and `base0F` to the same slot as `base0E`.
  - Alternatives: keep collapsed roles and shared bright grays.
  - Consequences: use distinct ANSI slots so constants, errors, keywords, and deprecated tags remain visually separable.

- [ ] D106 [R10]: Editor checks must assert evaluated configuration and behavior, not only file presence.
  - Context: conform, keymap, and dashboard gaps pass the current string-only check.
  - Alternatives: keep static `rg`/`test -f` assertions.
  - Consequences: add `nix eval` assertions for formatter maps and a bounded headless behavior probe.

- [ ] D107 [R10]: Drop the dead `pill_load_wallust` helper.
  - Context: reverification found one match, its definition at `home/modules/styles/pills.nix:442`, and no callers.
  - Alternatives: wire it into a consumer.
  - Consequences: remove the helper and any claim that its EOF-safe parsing is active.

- [ ] D108 [R50]: Dynamic Wallust/Noctalia colorschemes supersede a static palette registry.
  - Context: D78 claimed a canonical `home/modules/styles/palette.nix`; the module does not exist, and colors are now generated per wallpaper.
  - Alternatives: add a static neutral-ramp module that templates consume.
  - Consequences: retire D78, remove the architecture claim, and keep palette work limited to dynamic template correctness such as D105.

- [ ] D109 [R52]: Register every ACP provider Avante supports, including Pi, Claude Code, agy, and OpenCode.
  - Context: only a Pi provider is registered, with an impure `/home/hollowheap/...` path.
  - Alternatives: keep one provider with a machine-local path.
  - Consequences: derive provider paths from Nix or Home Manager, add the four named providers, and enumerate further supported providers from the installed Avante configuration before registration.

- [ ] D110 [R12]: Keep the HTTPS ingress design open until further discussion; do not adopt Tailscale certificates.
  - Context: public-trusted certs alone do not solve reachability from public Wi-Fi, and the user does not want Tailscale as the transport.
  - Alternatives: Tailscale HTTPS certs, split DNS with DNS-01, or WAN-forwarded 443 with DNS-01.
  - Consequences: defer changes to Caddy vhosts, `SSL_CERT_FILE`, and firewall ingress until a routing model is chosen.

- [ ] D111 [R06]: Build a squashfs NixOS installer image for acervus and supply the GPG private key externally at install time.
  - Context: `#install` is only a helper script, not an image; the user needs disko, `nixos-install`, and working Wi-Fi on first boot.
  - Alternatives: commit a passphrase-protected private key or document manual installation.
  - Consequences: add an ISO/squashfs output; never commit private keys, even passphrase-protected; read the key from external media or a prompt during installation.

- [ ] D112 [R13]: Declarative identity uses the GPG-derived SSH public key.
  - Context: `mutableUsers = false` requires declarative password and authorized-key sources.
  - Alternatives: plain SSH key or imperative identity.
  - Consequences: add the GPG-derived SSH public key to `users.users.hollowheap.openssh.authorizedKeys.keys` and source the password hash from sops.

- [ ] D113 [R39]: Keep the rclone mount and tune VFS/cache behavior for browsing speed.
  - Context: full VFS mount makes Nautilus directory loads slow; the user prefers to keep mount.
  - Alternatives: switch to one-way sync mirror or guarded bisync.
  - Consequences: tune `--dir-cache-time`, polling, fast fingerprinting, chunk size, and transfer concurrency; still add delete caps and backups to the bisync path.

- [x] D114 [R04]: Set iwd regulatory country to SG.
  - Context: world domain `00` reduces 5 GHz channels and transmit power.
  - Alternatives: leave iwd unset.
  - Consequences: `networking.wireless.iwd.settings.General.Country = "SG"` for hosts with Wi-Fi.

- [x] D115 [R37]: Keep ddclient IPv4-only.
  - Context: `usev6 = ""` disables AAAA updates.
  - Alternatives: enable IPv6 updates.
  - Consequences: no change to `roles/server/system/ddclient.nix`.

- [ ] D116 [R12]: Defer fovea HTTPS until acervus is installed and becomes the server.
  - Context: lacuna is a temporary host, DuckDNS points at a home that is not deployed, and fovea access is only required after acervus exists.
  - Alternatives: implement a temporary mesh-pin or WAN-forwarding workaround now.
  - Consequences: leave `tls internal`, `SSL_CERT_FILE`, and ingress unchanged until the server role moves to acervus.

- [ ] D117 [R06]: The squashfs installer uses a build-time ephemeral SSH/age keypair and never stores private key material in git or the target.
  - Context: the real GPG private key cannot be securely fetched remotely and must not be committed.
  - Alternatives: commit an encrypted private key or require a hardware token.
  - Consequences: build the ISO where the operator already has secret access, encrypt install-time secrets to an ephemeral age recipient, install with the ephemeral key, then bootstrap the real public key and rekey to the host key after first boot.

- [x] D118 [R13]: The declarative SSH key is the GPG auth subkey `FEEF0424DED6FB762A6F4747BD8DF946E631B8B9`.
  - Context: the email matches two GPG secret keys; only this subkey carries SSH auth capability.
  - Alternatives: use the primary signing/certification key.
  - Consequences: `users.users.hollowheap.openssh.authorizedKeys.keys` contains `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmWse+nAkLVADDX/hM3wO8ywLuIBXTyLj3ccor7r8NS openpgp:0xE631B8B9`.

- [x] D119 [R28]: Pi receives only the `opencode-go` provider; OpenCode and Crush keep both providers.
  - Context: Pi should not expose the `opencode` provider, while OpenCode may use both.
  - Alternatives: keep one shared wrapper that injects both API keys everywhere.
  - Consequences: `wrapWithOpenCodeKey` takes an explicit provider list; Pi passes only `opencode-go`.

- [x] D120 [R27]: End-of-turn output prints only non-empty lines, with `Blocked:` on its own line.
  - Context: empty `Next: none` or `Blocked: none` lines are noise, and a combined `Next|Blocked:` line hides state.
  - Alternatives: always print four lines with a combined status line.
  - Consequences: emit `Done:`, `Verified:`, `Next:`, and `Blocked:` only when each has content; keep `Blocked:` separate.

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
