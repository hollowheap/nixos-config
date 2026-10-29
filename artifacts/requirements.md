# Requirements

## GUI Layer

- [x] R01: The flake evaluates NixOS hosts and Home Manager from one lockfile.
  - Verify: nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath >/dev/null && nix eval .#nixosConfigurations.lacuna.config.system.build.toplevel.drvPath >/dev/null
  - Acceptance: The standalone Home Manager output evaluates from the same `home/` trees while NixOS rebuilds separately.
  - One lockfile keeps the system and user layers reproducible together, but each is applied by its own rebuild command.

- [x] R02: System packages and drivers use stable nixpkgs while the kernel, Home Manager, and user programs use unstable.
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.lib.version | grep -q "26\.05" && nix eval --raw .#homeConfigurations.hollowheap.pkgs.lib.version | grep -q "26\.11"
  - Acceptance: The NixOS primary and Home Manager package sets report different channels.
  - Stable drivers avoid regressions while user programs track current nixpkgs.

- [x] R03: Hosts compose one chassis profile, role modules, and explicit hardware and boot traits.
  - Verify: grep -q "profiles/laptop" hosts/lacuna/default.nix && grep -q "roles/server/system" hosts/lacuna/default.nix && test -f hosts/lacuna/hardware.nix
  - Acceptance: Imports express chassis, duty, and capability without `config.profile` checks.
  - The tree makes host intent reviewable without per-module enable flags.

- [x] R04: Touch, HDR, and hybrid graphics are gated by hardware traits.
  - Verify: grep -q "desktop.touch = true" hardware/touch.nix && grep -q "desktop.hdr = true" hardware/hdr.nix && grep -q "desktop.touch = true" home/hollowheap.nix && grep -q "hybrid-gpu" hosts/acervus/default.nix
  - Acceptance: Lacuna imports Intel, touch, and HDR traits; acervus imports hybrid Intel + Nvidia.
  - Hardware capabilities stay orthogonal and host-specific.

- [x] R05: Boot, storage, TPM2, and Secure Boot are declarative.
  - Verify: for f in grub tpm secure-boot minegrub kernel plymouth; do test -f boot/$f.nix; done && test -f hosts/lacuna/disko.nix
  - Acceptance: GRUB, TPM2 initrd, sbctl signing, Plymouth, Minegrub, and LUKS/BTRFS are configured from the flake.
  - The boot path is reproducible and auditable.

## Services & Desktop

- [x] R06: Lacuna runs the server role; acervus stays headless; secrets decrypt on lacuna.
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[true,true,true,true\]'
  - Acceptance: Headscale, Vaultwarden, Caddy, and ddclient run on lacuna with sops-managed secrets.
  - Keeping the server role local avoids a premature Vaultwarden migration.

- [x] R07: The desktop keeps Hyprland, Noctalia, and UWSM system-managed while Home Manager owns the user session.
  - Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Acceptance: Greeter, portals, and compositor package stay in `roles/desktop/system`; user settings live in `home/modules/environment` and `home/modules/styles`.
  - The login path stays stable while user configuration iterates independently.

- [x] R08: Home Manager modules are discovered recursively and share desktop data centrally.
  - Verify: grep -q "import-tree ./modules" home/hollowheap.nix && grep -q "primaryScale" modules/options/desktop.nix && grep -q "homeUserNames" flake/default.nix
  - Acceptance: No `home/cli.nix` or `home/gui.nix` entrypoints; `home/modules` loads with `import-tree`; Hyprland and the greeter read the same monitor and scale values.
  - Modules own their options and wiring; only shared desktop data is centralized.

## Special Hosts & Checks

- [x] R09: `fovea` evaluates as a nix-on-droid output on unstable aarch64.
  - Verify: nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx 24.05
  - Acceptance: The root Termux config evaluates without a NixOS host directory.
  - Termux shares the repository without pulling NixOS boot or hardware modules.

- [x] R10: Structural invariants are enforced by flake checks.
  - Verify: nix flake check
  - Acceptance: Profile, role, hardware, boot, Home Manager, and nix-on-droid layout are checked.
  - Regressions fail before activation instead of relying on prose.

- [x] R15: Flake checks live in a dedicated `tests/` tree and split by domain.
  - Verify: nix build .#checks.x86_64-linux.layout .#checks.x86_64-linux.policy .#checks.x86_64-linux.hardware .#checks.x86_64-linux.home .#checks.x86_64-linux.services .#checks.x86_64-linux.users
  - Acceptance: `tests/default.nix` loads each domain file as a separate flake check.
  - Domain checks isolate failures and keep the flake composition file small.

- [x] R16: The CLI baseline includes a working shell and terminal toolset.
  - Verify: test -f home/modules/shell/zsh.nix && nix eval .#homeConfigurations.hollowheap.config.programs.zsh.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.programs.eza.enable | grep -qx true
  - Acceptance: zsh, zoxide, git, direnv, tealdeer, eza, fzf, ripgrep, fd, bat, yazi, lazygit, and jq evaluate in the CLI tier.
  - A usable terminal baseline should not depend on the graphical tier.

## Open Requirements

- [x] R11: App bundles separate CLI baseline, GUI apps, and gaming apps.
  - Verify: test -f home/modules/programs/gaming/prismlauncher.nix && ! grep -Rq "prismlauncher" home/modules/ai home/modules/core home/modules/environment home/modules/shell home/modules/styles
  - Acceptance: PrismLauncher is opt-in and absent from CLI-only hosts.
  - Optional apps should not expand the default CLI footprint.

- [ ] R12: Publicly trusted Caddy certificates are available via DNS-01 when mesh clients need them.
  - Verify: grep -q "dns duckdns" roles/server/system/default.nix
  - Acceptance: Caddy can issue public certs without loopback-only trust.
  - Internal TLS remains the loopback default until public trust is required.

- [ ] R13: User passwords and SSH keys are declarative.
  - Verify: nix eval .#nixosConfigurations.lacuna.config.users.users.hollowheap.hashedPasswordFile >/dev/null
  - Acceptance: Password hashes and authorized keys come from sops, and mutable users are disabled.
  - Declarative identity removes imperative `passwd` and key drift.

- [x] R14: Additional hyprgrass gestures are available on the touch device.
  - Verify: grep -q 'kind = "longpress"' home/modules/environment/touch.nix
  - Acceptance: Long-press, multi-finger, and edge gestures map to window and launcher actions.
  - Touch navigation should cover more than workspace swipes and the on-screen keyboard.

- [x] R17: Home Manager feature parity with the sibling repository across CLI, GUI, editor/AI, and auxiliary services.
  - Verify: test -f home/modules/shell/starship.nix && test -f home/modules/programs/gui/ghostty.nix && test -f home/modules/programs/opencode.nix
  - Acceptance: Each functional slice is ported and evaluates before parity is claimed.
  - The current HM tree ports the CLI core, visual baseline, editor/AI, and harness modules; verify the remaining parity inventory before closing.

- [x] R18: An on-demand retrospective skill audits active session execution and compliance.
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.retro.description | grep -q "retrospective"
  - Acceptance: Retro evaluates tool efficiency, failure counts, rule compliance, and winning patterns directly from the active session context upon explicit invocation.
  - Intra-session audits produce empirical improvements for repo rules and harness conventions.

- [x] R19: A cross-session audit skill inspects compacted session transcripts for systemic cognitive loops and blind spots.
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.corpus-audit.description | grep -q "corpus-audit"
  - Acceptance: `corpus-audit` audits multiple session logs to detect workspace fact blind spots, recurring cognitive traps, knowledge amnesia, and tool waste, feeding improvements into harness authoring.
  - Multi-session meta-auditing provides the empirical evidence needed to improve harness bindings and agent system prompts.

- [x] R20: Neovim configuration is modularized into co-located domain modules for plugins, options, and keymaps.
  - Verify: test -f home/modules/programs/nvim/quickfix.nix && test -f home/modules/programs/nvim/preview.nix && test -f home/modules/programs/nvim/editing.nix
  - Acceptance: Domain modules (`quickfix.nix`, `preview.nix`, `editing.nix`, etc.) co-locate lazy plugin definitions, options, and keybinds instead of maintaining a monolithic `keymaps.nix`.
  - Co-locating keymaps and options with plugin declarations prevents orphan mappings and configuration scatter.

- [x] R21: Server system role is decomposed into cohesive vertical domain slices.
  - Verify: test -f roles/server/system/caddy.nix && test -f roles/server/system/headscale.nix && test -f roles/server/system/vaultwarden.nix && test -f roles/server/system/ddclient.nix
  - Acceptance: `roles/server/system/` decomposes monolithic Caddy, Headscale, Vaultwarden, and DDclient into isolated service modules where daemons declare their own reverse proxy virtualHosts.
  - Slices co-locate daemon configuration, ports, secrets, and reverse proxy definitions without leaking into a monolithic Caddy block.

- [x] R22: Home Manager modules are categorized into distinct terminal, cli, and programs domain boundaries.
  - Verify: test -d home/modules/terminal && test -d home/modules/cli && test -d home/modules/programs
  - Acceptance: Shell runtime and multiplexing live in `terminal/`, standalone headless utilities live in `cli/`, and GUI apps, editors, and agent harnesses live in `programs/`.
  - Clear architectural boundaries separate prompt/terminal lifecycle from headless CLI tools and heavy application packages.

- [x] R23: Integrate OMP (`oh-my-pi`) coding agent with Home Manager and shared `ai.*` abstractions.
  - Verify: nix eval .#homeConfigurations.hollowheap.config.programs.omp.enable | grep -qx true
  - Acceptance: `programs.omp` installs the package and binds shared skills, agents, disciplines, rules, and hooks into native `~/.omp/agent/` files.
  - OMP provides IDE-level LSP, DAP debugging, and hashline edits natively in the terminal.

- [x] R24: Disable built-in Pi extensions (`tool-search`, `mcp`, `llama.cpp`) via settings overrides.
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.pi-coding-agent.settings.extensions | grep -q "builtin:tool-search"
  - Acceptance: `programs.pi-coding-agent.settings.extensions` excludes `builtin:tool-search`, `builtin:mcp`, and `builtin:llama.cpp`.

- [x] R25: Consolidate wallpaper theming into Noctalia's native hook and Wallust templates.
  - Verify: nix eval .#homeConfigurations.hollowheap.config.programs.noctalia.settings.hooks.wallpaper_changed | grep -q "wallust"
  - Acceptance: `wallpaper_changed` directly executes `wallust run` and triggers GTK/icon accents and OpenRGB; user stub templates are dropped; icon theme updates apply to dconf, gsettings, and GTK settings.ini.

- [x] R26: Neovim in-buffer diagram and image rendering with Kitty graphics protocol.
  - Verify: nix eval .#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.lazy.plugins."diagram.nvim".setupModule | grep -q "diagram"
  - Acceptance: `diagram.nvim` and `image.nvim` are integrated into Neovim alongside CLI renderers (imagemagick, mermaid-cli, plantuml, d2, graphviz) to render diagrams inline in Markdown buffers under Ghostty.

- [ ] R27: Declared AI agent capabilities are the capabilities actually enforced.
  - Verify: nix build .#checks.x86_64-linux.ai
  - Acceptance: An architect subagent can write under `artifacts/` and delegate to `scout`; no invalid permission key is emitted.
  - Tool stripping is an ordering bug, not an intended restriction.

- [ ] R28: Every AI harness renders the shared agent brief and resolves model and effort from one tier table.
  - Verify: nix build .#checks.x86_64-linux.ai
  - Acceptance: Non-OpenCode harnesses contain the agent prompt, and no harness hardcodes a model outside `ai.tiers`.
  - A single renderer prevents per-harness behavior drift.

- [ ] R29: One MCP server registry feeds every harness that supports MCP.
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.mcp.servers
  - Acceptance: Enabling `capabilities.mcp` yields the same servers in OpenCode, Codex, Crush, and Copilot.
  - `capabilities.mcp` currently yields no tools anywhere.

- [ ] R30: Hook commands, matchers, and harness filters have one contract and fail closed before tools run.
  - Verify: nix build .#checks.x86_64-linux.ai
  - Acceptance: Replacing a hook command affects every harness; malformed pre-tool payloads block rather than pass.
  - Renderers currently reimplement the hook protocol inconsistently.

- [ ] R31: AI spend, telemetry, fallback, and compaction policy is explicit.
  - Verify: nix eval .#homeConfigurations.hollowheap.config.programs.pi-coding-agent.settings.enableInstallTelemetry
  - Acceptance: Install telemetry is off, a spend cap exists, and a provider outage has a declared fallback.
  - Unbounded loops and quota exhaustion are cost failures.

- [ ] R32: Pointer, gesture, keyboard, and touch policy is explicit and shared across compositor, greeter, and console.
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.programs.hyprland.settings.input.touchpad.natural_scroll | grep -qx true
  - Acceptance: Two-finger scrolling follows touch, a three-finger workspace gesture exists, and one keyboard layout value drives all sessions.
  - Inversion is Hyprland's unset default, not hardware.

- [ ] R33: Lid close and battery policy protects unsaved work.
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.logind.settings.Login.HandleLidSwitch | grep -qx suspend-then-hibernate
  - Acceptance: Lid close hibernates after a bounded delay, and a battery charge threshold is applied when the firmware exposes it.
  - Suspend-until-empty loses work.

- [ ] R34: Network services expose only intended ports and interfaces with no unauthenticated admin surface.
  - Verify: nix build .#checks.x86_64-linux.services
  - Acceptance: Caddy admin is off or authenticated, ports are scoped to loopback/mesh, and sshd disables password auth.
  - Mesh-only assumptions are currently false.

- [ ] R35: Vaultwarden registration and client identity policy is explicit.
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services.vaultwarden.config.SIGNUPS_ALLOWED | grep -qx false
  - Acceptance: Signups are closed or allowlisted, and the proxy identity header matches Caddy's output.
  - Open registration plus one rate-limit bucket is a lockout risk.

- [ ] R36: Headscale enforces ACLs, node expiry, trusted proxies, and a declared relay policy.
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.headscale.settings.policy.path
  - Acceptance: Default-deny ACLs exist, expired nodes are removed, and UDP 3478 is only open when a DERP server listens.
  - The current tailnet is allow-all with permanent nodes.

- [ ] R37: The public DNS record cannot silently freeze.
  - Verify: nix build .#checks.x86_64-linux.services
  - Acceptance: ddclient can read its secret as its service user, updates IPv6 where available, and a failed update is observable.
  - A stale record makes the mesh unreachable.

- [ ] R38: Internal TLS certificates renew automatically and expiry is monitored.
  - Verify: nix build .#checks.x86_64-linux.services
  - Acceptance: No static leaf certificate is trusted; renewal is automatic; expiry raises an alert before it fires.
  - Manual PEM expiry breaks every client at once.

- [ ] R39: rclone mounts and syncs cannot delete or hang unbounded.
  - Verify: nix build .#checks.x86_64-linux.home
  - Acceptance: Syncs set a delete guard and backup directory, mounts have timeouts, and bisync has a resync procedure.
  - The current mirror propagates remote deletion with unlimited deletes.

- [ ] R40: A failed update cannot exhaust the rollback window.
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.configurationLimit | grep -qx 10
  - Acceptance: At least ten generations, a saved default, and a panic/watchdog policy exist.
  - Three generations and seven days is too narrow.

- [ ] R41: LUKS and rescue access have a tested recovery path.
  - Verify: nix build .#checks.x86_64-linux.policy
  - Acceptance: A recovery key or header backup exists, and a rescue credential works without physical media.
  - Recovery must not depend on undocumented imperative state.

- [ ] R42: Firmware capability belongs to every host, not to Bluetooth.
  - Verify: nix eval .#nixosConfigurations.acervus.config.hardware.enableRedistributableFirmware | grep -qx true
  - Acceptance: Wi-Fi, GPU, audio, and regulatory firmware are enabled on both hosts.
  - A Bluetooth trait currently owns a host-wide capability.

- [ ] R43: Storage layout and swap are owned by the host, not a shared trait.
  - Verify: nix build .#checks.x86_64-linux.hardware
  - Acceptance: One owner declares swap and mount options; no duplicate `swapDevices` entries.
  - The shared trait duplicates disko and assumes one host's layout.

- [ ] R44: Hybrid GPU policy is explicit per host.
  - Verify: nix build .#checks.x86_64-linux.hardware
  - Acceptance: Offload or reverse-sync is chosen per host, and Nvidia environment variables are not global.
  - Global Nvidia env defeats PRIME and drains battery.

- [ ] R45: Disk health and store free space are observable.
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.smartd.enable | grep -qx true
  - Acceptance: SMART failures are surfaced, and Nix keeps a free-space floor.
  - A full store stalls updates and vault writes.

- [ ] R46: Wi-Fi regulatory country and WPA2 fallback are explicit.
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.networking.wireless.iwd.settings.General.Country
  - Acceptance: A country is set and WPA2-only access points can be joined.
  - SAE-only profiles fail on WPA2 hotspots.

- [ ] R47: RGB state survives reboot and resume.
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.hardware.openrgb.startupProfile
  - Acceptance: A startup profile is applied and re-applied after resume.
  - Controllers reset to firmware defaults.

- [ ] R48: fovea runs a headless Home Manager profile that shares platform-neutral modules.
  - Verify: nix eval --raw .#nixOnDroidConfigurations.fovea.activationPackage.drvPath
  - Acceptance: The fovea activation package evaluates with flakes, wake lock, storage helpers, and no desktop-only modules.
  - A package stub is not a usable mobile environment.

- [ ] R49: fovea has an explicit identity and secret policy.
  - Verify: nix build .#checks.aarch64-linux.fovea
  - Acceptance: Git identity and signing keys are separate from lacuna, and `sops` has no unusable recipient.
  - Copying the only age key to a phone is unacceptable.

- [ ] R50: One palette authority and one theme-consumer registry own rendering.
  - Verify: nix build .#checks.x86_64-linux.home
  - Acceptance: A new consumer registers data only; the theme renders on activation and wallpaper change.
  - Two extractors currently produce two accent colors.

- [ ] R51: Every theme consumer selects its generated artifact.
  - Verify: nix build .#checks.x86_64-linux.home
  - Acceptance: btop selects its theme, yazi loads its flavor and tmtheme, fzf uses the ANSI palette, and agent TUIs follow it.
  - Rendered-but-unselected files are dead config.

- [ ] R52: The editor has one provider and working diagnostics, formatting, session, and clipboard.
  - Verify: nix build .#checks.x86_64-linux.home
  - Acceptance: One `nvim` package wins, diagnostics and format-on-save run, sessions restore, and clipboard works locally and over SSH.
  - Duplicate providers and inert options undermine the editor.

- [ ] R53: Shell behavior has no dead aliases, invisible suggestions, or stolen control keys.
  - Verify: nix build .#checks.x86_64-linux.home
  - Acceptance: fzf-tab resolves its helper, starship styles are valid, `LS_COLORS` and `PAGER` exist, and `C-p` reaches programs.
  - Prompt and completion failures are silent today.

- [ ] R54: CLI signing, hooks, editor, and SSH agent policy has one owner.
  - Verify: nix build .#checks.x86_64-linux.home
  - Acceptance: A signing key is explicit, tag pushes verify tags, repo hooks still run, and one agent owns SSH.
  - Three partial agent configs disagree.

- [ ] R55: Default handlers, DRM, media, and discovery point at installed working tools.
  - Verify: nix build .#checks.x86_64-linux.home
  - Acceptance: Text, image, video, and audio open the right app; internal DNS resolves in the browser; camera, printer, and scanner discovery work.
  - Current handlers route common files to non-players.

## Open Questions

- Q01: Which browser, terminal, mail, file manager, screenshot, and gaming bundles land after R11?
- Q02: Should standalone `homeConfigurations.hollowheap` remain the only Home Manager output for lacuna and fovea?
- Q03: Should Vaultwarden move to acervus once the migration is tested?
- Q04: Which host actually has hybrid Nvidia: lacuna or acervus?
- Q05: Is acervus installed, or still a placeholder shell?
- Q06: Is hibernate required on lacuna, or should sleep remain suspend-only?
- Q07: Are the external display ports wired to the dGPU?
- Q08: Does the ISP provide usable IPv6?
- Q09: Does fovea need signed commits and repo secrets, or only a portable shell?
- Q10: Are network printers or scanners in use, so discovery and SANE matter?
