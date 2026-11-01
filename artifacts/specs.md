# Specifications

### System Foundation

- [x] S01 [R01] [D01]: NixOS hosts and standalone Home Manager evaluate from one flake
  - Verify: nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath >/dev/null && nix eval .#nixosConfigurations.lacuna.config.system.build.toplevel.drvPath >/dev/null
  - Arch: System Shape
  - Seam: flake outputs and host wiring.
  - Behavior: both outputs build from `home/` and `hosts/`.
  - Failures: missing input, missing host, divergent option sets.

- [x] S02 [R02] [D02]: NixOS stays on release-26.05 while standalone Home Manager and user programs use unstable
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.lib.version | grep -q "26\.05" && nix eval --raw .#homeConfigurations.hollowheap.pkgs.lib.version | grep -q "26\.11"
  - Arch: System Shape
  - Seam: package-set split.
  - Behavior: NixOS and Home Manager report different nixpkgs channels.
  - Failures: global pkgs forced stable, missing HM override, mixed drivers.

- [x] S03 [R03] [D03]: Hosts compose one profile, role modules, and explicit traits
  - Verify: grep -q "profiles/laptop" hosts/lacuna/default.nix && grep -q "roles/server/system" hosts/lacuna/default.nix && test -f hosts/lacuna/hardware.nix
  - Arch: System Shape
  - Seam: host import list.
  - Behavior: chassis, duty, and capability are separate paths.
  - Failures: two profiles, hidden hardware imports, `config.profile` checks.

- [x] S04 [R04] [D04]: Touch and HDR gate compositor settings through hardware flags
  - Verify: grep -q "desktop.touch = true" hardware/touch.nix && grep -q "desktop.hdr = true" hardware/hdr.nix && grep -q "desktop.touch = true" home/hollowheap.nix && grep -Rq "config.desktop.touch" home/modules/environment
  - Arch: System Shape
  - Seam: hardware traits and the standalone Home Manager config.
  - Behavior: lacuna's standalone HM sets both flags; compositor modules gate on them.
  - Failures: hardware trait missing, standalone config not enabling the flag, compositor ignoring it.

- [x] S05 [R04] [D05]: Lacuna is Intel-only; acervus composes Intel and Nvidia with PRIME
  - Verify: grep -q "hybrid-gpu" hosts/acervus/default.nix && ! grep -q "hybrid-gpu" hosts/lacuna/hardware.nix && nix eval .#nixosConfigurations.acervus.config.hardware.nvidia.prime.offload.enable | grep -qx true
  - Arch: System Shape
  - Seam: graphics hardware traits.
  - Behavior: hybrid offload evaluates on acervus only.
  - Failures: lacuna importing Nvidia, missing PRIME, stale bus IDs.

- [x] S06 [R05] [D06]: Boot integration lives in the top-level `boot/` tree
  - Verify: for f in grub tpm secure-boot minegrub kernel plymouth; do test -f boot/$f.nix; done && test ! -e modules/boot/boot.nix
  - Arch: System Shape
  - Seam: boot module boundary.
  - Behavior: hosts import boot components explicitly.
  - Failures: boot code under hardware or modules, missing GRUB/TPM files.

- [x] S07 [R05] [D07]: Lacuna declares LUKS and BTRFS storage with Disko
  - Verify: test -f hosts/lacuna/disko.nix && nix eval .#nixosConfigurations.lacuna.config.disko.devices.disk.main.type | grep -qx disk
  - Arch: System Shape
  - Seam: host storage configuration.
  - Behavior: GPT, LUKS, and BTRFS subvolumes evaluate.
  - Failures: missing disko module, unencrypted root, absent subvolumes.

- [x] S08 [R06] [D08]: Lacuna runs Headscale, Vaultwarden, Caddy, and ddclient; acervus does not
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[true,true,true,true\]' && nix eval --json .#nixosConfigurations.acervus.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[false,false,false,false\]'
  - Arch: System Shape
  - Seam: server role composition.
  - Behavior: only lacuna imports the server role.
  - Failures: duplicated services, acervus running the vault.

- [x] S09 [R06] [D09]: Caddy uses internal TLS for loopback names and tailscaled trusts its CA
  - Verify: grep -q "tls internal" roles/server/system/default.nix && grep -q "SSL_CERT_FILE" roles/server/system/default.nix
  - Arch: Operations & Security
  - Seam: loopback TLS and client trust.
  - Behavior: Headscale and Vaultwarden serve internal certs; tailscaled trusts the CA.
  - Failures: ACME attempts on hosts-file names, untrusted CA.

- [x] S10 [R06] [D10]: Sops secrets target lacuna's age key, install via systemd, and Vaultwarden reads its admin env
  - Verify: grep -q "&lacuna age1cum" .sops.yaml && grep -q "vaultwarden_env" secrets.yaml && grep -q "environmentFile" roles/server/system/default.nix && nix eval .#nixosConfigurations.lacuna.config.sops.useSystemdActivation | grep -qx true
  - Arch: Operations & Security
  - Seam: encrypted secrets and service consumption.
  - Behavior: activation writes `/run/secrets`; Vaultwarden reads `ADMIN_TOKEN`.
  - Failures: wrong recipient, missing secret, world-readable file.

- [x] S11 [R07] [D11]: The system keeps Hyprland, UWSM, and the greeter; Home Manager owns user settings
  - Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Arch: System Shape
  - Seam: system session versus HM session.
  - Behavior: package and portal stay system-managed.
  - Failures: duplicate compositor, missing greeter, HM owning portals.

- [x] S12 [R08] [D46]: Home Manager modules load recursively through `import-tree` with no central module list
  - Verify: grep -q "import-tree ./modules" home/hollowheap.nix && ! test -e home/cli.nix && ! test -e home/gui.nix
  - Arch: Module Seams
  - Seam: Home Manager module discovery.
  - Behavior: `home/modules` loads without cli/gui entrypoints; per-user files only set identity and options.
  - Failures: central import lists, missing modules, duplicate option declarations.

- [x] S13 [R08] [D13]: The neutral shortcut catalog renders through Hyprland
  - Verify: nix eval .#homeConfigurations.hollowheap.config.desktop.shortcuts --apply 's: (builtins.hasAttr "close-window" s) && (builtins.hasAttr "focus-window-left" s) && (builtins.hasAttr "move-window-to-workspace" s)' | grep -qx true
  - Arch: Module Seams
  - Seam: shared shortcut option and compositor renderer.
  - Behavior: catalog entries become Hyprland binds.
  - Failures: missing action mapping, duplicate keybinds.

- [x] S14 [R09] [D14]: `fovea` evaluates as a nix-on-droid output
  - Verify: nix eval .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx "24.05" && test ! -d hosts/fovea
  - Arch: System Shape
  - Seam: Termux flake output.
  - Behavior: the root config evaluates on unstable aarch64.
  - Failures: host enumeration picking up Termux, missing input.

- [x] S15 [R10] [D15]: Flake checks enforce the layout
  - Verify: nix flake check
  - Arch: Module Seams
  - Seam: flake `checks`.
  - Behavior: profile, role, hardware, boot, Home Manager, and Termux paths are checked.
  - Failures: stale paths, missing files, forbidden loaders.

- [x] S16 [R02] [D16]: Unfree packages are declarable and merge into both package sets
  - Verify: nix eval .#nixosConfigurations.lacuna.config.unfreePackages --apply 'ps: builtins.elem "steam" ps' | grep -qx true && grep -q "config.unfreePackages" modules/system/nixpkgs.nix
  - Arch: Data & Contracts
  - Seam: nixpkgs license policy.
  - Behavior: modules append their own unfree names.
  - Failures: hardcoded list, predicate not applied to unstable.

- [x] S17 [R03] [D17]: Admin groups compose from module ownership
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.extraGroups | grep -q '"podman"' && nix eval --json .#nixosConfigurations.lacuna.config.users.adminExtraGroups | grep -q '"podman"' && ! grep -q '"podman"' modules/system/users.nix
  - Arch: Module Seams
  - Seam: user group seam.
  - Behavior: Podman, Wi-Fi, RGB, TPM, and graphics modules append groups.
  - Failures: hardcoded groups, missing module ownership.

### Host Infrastructure

- [x] S18 [R05] [D18]: Acervus ignores lid close, disables suspend, and has no charge cap
  - Verify: nix eval .#nixosConfigurations.acervus.config.services.logind.settings.Login.HandleLidSwitch | grep -qx ignore && nix eval .#nixosConfigurations.acervus.config.systemd.sleep.settings.Sleep.AllowSuspend | grep -qx no && ! grep -R "charge_control_end_threshold" hosts/acervus
  - Arch: System Shape
  - Seam: host power policy.
  - Behavior: the server stays awake with the lid closed.
  - Failures: suspend on AC, battery cap reintroduced.

- [x] S19 [R06] [D19]: Vaultwarden reads `ADMIN_TOKEN` from sops
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services.vaultwarden.environmentFile | grep -q "/run/secrets/vaultwarden_env" && grep -q "vaultwarden_env:" secrets.yaml
  - Arch: Data & Contracts
  - Seam: Vaultwarden admin configuration.
  - Behavior: the admin panel is enabled without plaintext secrets.
  - Failures: missing env file, token in git.

- [x] S20 [R08] [D20]: The visual baseline evaluates and renders under Hyprland
  - Verify: nix eval .#homeConfigurations.hollowheap.config.gtk.theme.name >/dev/null && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Arch: Framework & Library Choices
  - Seam: Home Manager visual options.
  - Behavior: theme, fonts, cursor, icons, Hyprland appearance, and Noctalia evaluate.
  - Failures: missing theme, unresolved package, absent Noctalia config.

- [x] S21 [R11] [D21]: Optional apps live in `home/modules/programs/gaming` and stay out of the CLI baseline
  - Verify: test -f home/modules/programs/gaming/prismlauncher.nix && ! grep -R "prismlauncher" home/modules/programs/default.nix
  - Arch: Module Seams
  - Seam: app bundle boundary.
  - Behavior: gaming and GUI apps are explicit imports.
  - Failures: PrismLauncher in CLI, missing bundle.

- [ ] S22 [R12] [D22]: Caddy can issue publicly trusted certs via DuckDNS DNS-01
  - Verify: grep -q "dns duckdns" roles/server/system/default.nix
  - Arch: Operations & Security
  - Seam: Caddy certificate issuance.
  - Behavior: DNS-01 replaces internal TLS when public trust is needed.
  - Failures: ACME port exposure, missing DuckDNS token.

- [ ] S23 [R13] [D23]: User identity is sops-backed and immutable
  - Verify: nix eval .#nixosConfigurations.lacuna.config.users.users.hollowheap.hashedPasswordFile >/dev/null
  - Arch: Data & Contracts
  - Seam: user account configuration.
  - Behavior: passwords and SSH keys come from secrets.
  - Failures: imperative `passwd`, missing hashed password.

- [x] S24 [R14] [D24]: Additional hyprgrass gestures cover window and launcher actions
  - Verify: grep -q 'kind = "longpress"' home/modules/environment/touch.nix
  - Arch: Module Seams
  - Seam: touch compositor module.
  - Behavior: long-press and multi-finger gestures map to native actions.
  - Failures: gesture conflicts, unsupported action names.

- [x] S25 [R05] [D25]: GRUB and Minegrub use a 3-second timeout
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.loader.timeout | grep -qx 3 && grep -q "set timeout=3" pkgs/double-minegrub-menu.nix
  - Arch: System Shape
  - Seam: bootloader wait time.
  - Behavior: both the loader and theme menu wait three seconds.
  - Failures: packaged timeout remains 15 seconds, loader differs.

- [x] S26 [R04] [D26]: Intel graphics use early i915 KMS and fastboot
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.kernelModules | grep -q '"i915"' && nix eval .#nixosConfigurations.lacuna.config.boot.kernelParams | grep -q 'i915.fastboot=1'
  - Arch: System Shape
  - Seam: Intel graphics hardware trait.
  - Behavior: i915 initializes early and preserves the GOP framebuffer.
  - Failures: late KMS, missing fastboot, panel reinitialization.

- [x] S27 [R05] [D27]: TPM2 unlock and PCR measurement run in systemd initrd
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.tpm2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.boot.initrd.luks.devices.crypted.crypttabExtraOpts | grep -q "tpm2-device=auto"
  - Arch: System Shape
  - Seam: encrypted boot.
  - Behavior: the LUKS device unlocks with TPM2 and measures PCRs.
  - Failures: missing tpm_tis, passphrase-only boot, unmeasured unlock.

- [x] S28 [R05] [D28]: Secure Boot install hooks sign GRUB and kernels with sbctl
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.extraInstallCommands | grep -q sbctl
  - Arch: Operations & Security
  - Seam: bootloader signing.
  - Behavior: GRUB and kernels are signed during install.
  - Failures: unsigned binaries, missing sbctl, wrong EFI path.

- [x] S29 [R05] [D29]: Minegrub packages stay in pkgs and theme selection stays in boot
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.theme.name | grep -q double-minegrub-menu && test ! -e hardware/minegrub.nix
  - Arch: System Shape
  - Seam: boot theme selection.
  - Behavior: the theme package and mainmenu redirection evaluate.
  - Failures: hardware minegrub module, missing package, broken menu path.

- [x] S30 [R06] [D30]: PipeWire provides ALSA and PulseAudio compatibility
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.pipewire.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.pipewire.pulse.enable | grep -qx true
  - Arch: Framework & Library Choices
  - Seam: desktop audio stack.
  - Behavior: 32-bit ALSA and PulseAudio clients share PipeWire.
  - Failures: missing ALSA support, no PulseAudio bridge.

- [x] S31 [R06] [D31]: systemd-resolved uses Cloudflare DNS-over-TLS
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.resolved.extraConfig | grep -q "security.cloudflare-dns.com"
  - Arch: Operations & Security
  - Seam: DNS resolution.
  - Behavior: upstream queries use DNS-over-TLS.
  - Failures: plaintext DNS, wrong resolver, no TLS.

- [x] S32 [R06] [D32]: NetworkManager uses iwd and sops-backed Wi-Fi profiles
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.networking.networkmanager.wifi.backend | grep -qx iwd && grep -q "wireless_env" hardware/wifi.nix
  - Arch: Operations & Security
  - Seam: wireless networking.
  - Behavior: iwd manages Wi-Fi and profiles read encrypted credentials.
  - Failures: wpa_supplicant backend, missing secret, invalid profile.

- [x] S33 [R06] [D33]: Removable media and iOS devices work through desktop daemons
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.udisks2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.gvfs.enable | grep -qx true
  - Arch: Operations & Security
  - Seam: desktop device services.
  - Behavior: file managers can mount media and access iOS devices.
  - Failures: missing gvfs, no usbmuxd, root-only mounts.

- [x] S34 [R05] [D34]: Laptop thermal and power policy lives in the laptop profile
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.thermald.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.upower.enable | grep -qx true
  - Arch: System Shape
  - Seam: chassis policy.
  - Behavior: thermald, upower, and power-profiles-daemon are enabled.
  - Failures: hardware trait owning policy, missing services.

- [x] S35 [R01] [D35]: Recursive module discovery remains in lib
  - Verify: grep -q "mkModuleLoader" modules/default.nix && test -f lib/default.nix
  - Arch: Module Seams
  - Seam: module loading.
  - Behavior: `modules/default.nix` discovers all module files.
  - Failures: manual import drift, missing loader.

- [x] S36 [R01] [D36]: The package overlay discovers local derivations
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.double-minegrub-menu.name | grep -q double-minegrub-menu && grep -q "kebabToCamel" pkgs/default.nix
  - Arch: Module Seams
  - Seam: local package overlay.
  - Behavior: local files resolve through `overlays.default`.
  - Failures: missing package, broken directory scope.

- [x] S37 [R01] [D37]: Every language devShell and alias evaluates
  - Verify: for s in default ts c rust python pico nix typescript js clang cpp; do nix eval .#devShells.x86_64-linux.$s.name >/dev/null || exit 1; done
  - Arch: Module Seams
  - Seam: flake devShells.
  - Behavior: language shells and aliases resolve on unstable.
  - Failures: missing shell, stale alias.

- [x] S38 [R06] [D38]: Cachix substituters are trusted alongside the NixOS cache
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "nix-on-droid.cachix.org" && nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "hyprland.cachix.org"
  - Arch: Operations & Security
  - Seam: binary cache policy.
  - Behavior: Termux, community, and Hyprland caches are trusted.
  - Failures: missing key, untrusted cache.

- [x] S39 [R06] [D39]: Server ingress ports live with the Headscale role
  - Verify: grep -q "Headscale ingress" roles/server/system/default.nix && grep -q "allowedUDPPorts = \[ 3478 \]" roles/server/system/default.nix
  - Arch: Operations & Security
  - Seam: server firewall configuration.
  - Behavior: Caddy and Headscale own ports 80/443 and 3478.
  - Failures: ports in a generic module, client opening server ports.

- [x] S40 [R05] [D40]: BTRFS scrub, zram, and mount policy are enabled
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.btrfs.autoScrub.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.zramSwap.enable | grep -qx true
  - Arch: Operations & Security
  - Seam: filesystem policy.
  - Behavior: monthly scrub, zram swap, and explicit mount options evaluate.
  - Failures: missing scrub, no zram, lost mount options.

### Modules and Checks

- [x] S41 [R15] [D41]: Domain checks live in `tests/` and load automatically
  - Verify: nix build .#checks.x86_64-linux.layout .#checks.x86_64-linux.policy .#checks.x86_64-linux.hardware .#checks.x86_64-linux.home .#checks.x86_64-linux.services .#checks.x86_64-linux.users
  - Arch: Module Seams
  - Seam: flake `checks` output and `tests/` loader.
  - Behavior: each `tests/<domain>.nix` becomes `checks.x86_64-linux.<domain>`.
  - Failures: loader misses a file, duplicate domain name, check build error.

- [x] S42 [R16] [D42]: The CLI baseline evaluates a shell and terminal toolset independently of the GUI tier
  - Verify: test -f home/modules/terminal/zsh.nix && nix eval .#homeConfigurations.hollowheap.config.programs.zsh.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.programs.eza.enable | grep -qx true
  - Arch: Module Seams
  - Seam: `home/modules` import-tree root.
  - Behavior: zsh, zoxide, git, direnv, tealdeer, and core terminal tools resolve.
  - Failures: missing module, GUI dependency, duplicate option.

- [x] S43 [R17] [D43]: Remaining Home Manager slices evaluate before parity is claimed
  - Verify: test -f home/modules/terminal/starship.nix && test -f home/modules/programs/gui/ghostty.nix && test -f home/modules/programs/opencode.nix
  - Arch: Module Seams
  - Seam: Home Manager module parity.
  - Behavior: prompt theming, GUI apps, editor/AI, and auxiliary services land as separate slices.
  - Failures: treating infrastructure tasks as feature parity.

- [x] S44 [R08] [D46]: Shared desktop values drive Hyprland and the greeter
  - Verify: grep -q "primaryScale" modules/options/desktop.nix && grep -q "config.desktop.primaryScale" home/modules/programs/hyprland/hyprland.nix && grep -q "config.desktop.primaryScale" roles/desktop/system/default.nix
  - Arch: Module Seams
  - Seam: shared desktop data.
  - Behavior: monitor layout, primary output, scale, and font families have one source; Hyprland and Noctalia wire it independently.
  - Failures: duplicated scale constants, greeter drifting from compositor, font values duplicated across modules.

- [x] S45 [R08] [D47]: Hyprland keybinds are a reusable compositor module
  - Verify: test -f home/modules/programs/hyprland/keybinds.nix && grep -q "../../../lib/hyprland.nix" home/modules/programs/hyprland/keybinds.nix && ! grep -q "bind = map mkArgs" home/modules/programs/hyprland/hyprland.nix
  - Arch: Module Seams
  - Seam: compositor interaction policy.
  - Behavior: binds and submaps load from one module; host modules provide monitors, plugins, and window rules separately.
  - Failures: duplicated bind tables, helpers drift, keybinds missing from a host.

- [x] S46 [R08] [D48]: Compositor window dimensions are neutral options, not theme or Hyprland-specific data
  - Verify: test -f home/modules/environment/compositor.nix && grep -q "desktop.compositor" home/modules/environment/compositor.nix && grep -q "config.desktop.compositor" home/modules/programs/hyprland/hyprland.nix
  - Arch: Module Seams
  - Seam: compositor geometry.
  - Behavior: gaps, borders, radius, and bar height come from `desktop.compositor`; Hyprland and Noctalia consume them.
  - Failures: dimensions under `styles`, duplicated values, program-specific option names.

### AI and Editor

- [x] S47 [R20] [D51]: Neovim domain modules co-locate plugins, configuration, whichKey, and keymaps
  - Verify: test -f home/modules/programs/nvim/quickfix.nix && test -f home/modules/programs/nvim/preview.nix && test -f home/modules/programs/nvim/editing.nix && nix eval --raw .#homeConfigurations.hollowheap.config.programs.neovim.finalPackage.name >/dev/null
  - Arch: Framework & Library Choices
  - Seam: Neovim domain modularization.
  - Behavior: `quickfix.nix`, `preview.nix`, and `editing.nix` configure domain plugins and bindings directly; `core.nix` and `keymaps.nix` delegate domain logic without breaking existing editor keymaps.
  - Failures: orphan keymaps, broken lazy plugin definitions, module collisions.

- [x] S48 [R19] [D53]: Universal harness rules with eager/lazy skill partitioning
  - Verify: nix build .#checks.x86_64-linux.home && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Arch: Framework & Library Choices
  - Seam: `home/modules/ai/rules.nix` and `home/modules/ai/agents.nix`.
  - Behavior: `rules.nix` encodes runner declaration, exact verify, gate integrity, experiment timebox, and subagent concurrency clamps; `agents.nix` keeps primary agents lean by pruning domain UI skills to workers and review auditors.
  - Failures: syntax errors in rules, broken capability filters, missing skills in worker.

- [x] S49 [R19] [D54]: Frontend guidance is absorbed into the review UI lens
  - Verify: test -f assets/skills/review/references/ui.md
  - Arch: Framework & Library Choices
  - Seam: `assets/skills/review/references/ui.md`.
  - Behavior: UI authoring, accessibility, layout density, and token checks live in one review reference.
  - Failures: missing reference file or broken review routing.

- [x] S50 [R19] [D55]: Backend guidance is absorbed into the review backend lens
  - Verify: test -f assets/skills/review/references/backend.md && test -f assets/skills/modular-design/SKILL.md
  - Arch: Framework & Library Choices
  - Seam: `assets/skills/review/references/backend.md` and `assets/skills/modular-design/SKILL.md`.
  - Behavior: Transport-boundary validation, thin handlers, pure services, error mapping, timeouts, and pool shutdown live in the review backend lens; `modular-design` still owns architecture seams.
  - Failures: missing reference file, broken review routing, or missing modular-design skill.

- [x] S51 [R19] [D56]: Harness model routing and reasoning effort alignment
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.codex.settings && nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".kiro/agents/architect.json"'.text
  - Arch: Framework & Library Choices
  - Seam: `home/modules/programs/codex.nix`, `home/modules/programs/kiro-cli.nix`, `home/modules/ai/options.nix`.
  - Behavior: Codex settings and agents declare `model = "gpt-6-luna"` with `model_reasoning_effort = "xhigh"`; Kiro agents declare `claude-sonnet-5.5` at effort `low` for high tier (`architect`) and `claude-haiku-5.5` at effort `xhigh` for medium/low tiers; global `ai.tiers` default centralizes on `opencode-go`.
  - Failures: missing TOML keys, invalid JSON effort strings, broken eval.

- [x] S52 [R19] [D57]: Declarative dynamic API key delivery for AI harnesses
  - Verify: env -u OPENCODE_API_KEY pi auth check --provider opencode-go && zsh -c 'source ~/.config/zsh/.zshrc && echo $OPENCODE_API_KEY'
  - Arch: Framework & Library Choices
  - Seam: `home/modules/terminal/zsh.nix`, `home/modules/programs/opencode.nix`, `home/modules/programs/pi-coding-agent.nix`, `home/modules/ai/hooks.nix`.
  - Behavior: OpenCode, Pi, and Crush resolve `OPENCODE_API_KEY` and `OPENCODE_GO_API_KEY` dynamically via `rbw`; `pi` natively evaluates `!rbw get --folder dev/keys opencode` from `~/.pi/agent/auth.json`; Zsh injects keys on startup and preexec before `opencode*`, `pi*`, `crush*`, `kiro*`, or `codex*`.
  - Failures: missing key in harness runtime, hardcoded secrets in dotfiles, hung repomap in bare `$HOME`.

### Desktop and Theme

- [x] S53 [R08] [D58]: Declarative XDG user directories and Wallust template unification
  - Verify: test -f ~/.config/user-dirs.dirs && grep -q 'XDG_TEMPLATES_DIR' ~/.config/user-dirs.dirs && test -d ~/.local/share/templates
  - Arch: Framework & Library Choices
  - Seam: `home/modules/environment/session.nix`, `home/modules/programs/wallust.nix`, `home/modules/programs/noctalia.nix`.
  - Behavior: `xdg.userDirs` declares standard user folders and redirects template/desktop/public to `~/.local/share/`; Wallust templates deploy into `${config.xdg.userDirs.templates}` and mirror to `~/.config/wallust/templates`; Noctalia invokes Wallust with `--templates-dir`.
  - Failures: missing user-dirs.dirs, broken wallust template resolution, cluttered `$HOME`.

- [x] S54 [R21] [D59]: Vertical domain slices for server role daemons
  - Verify: test -f roles/server/system/caddy.nix && test -f roles/server/system/headscale.nix && test -f roles/server/system/vaultwarden.nix && test -f roles/server/system/ddclient.nix && nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run
  - Arch: Module Seams
  - Seam: `roles/server/system/{default,caddy,headscale,vaultwarden,ddclient,domains}.nix`.
  - Behavior: `caddy.nix` provides base reverse proxy engine, plugin wrapper, and DNS-01 certs; `headscale.nix`, `vaultwarden.nix`, and `ddclient.nix` configure respective services, secrets, and virtualHost reverse proxy mappings; `default.nix` aggregates imports; `tests/services.nix` passes.
  - Failures: conflicting vhost names, missing firewall ports, broken sops secret bindings, circular dependencies.

- [x] S55 [R22] [D60]: Decoupled home module taxonomy across terminal, cli, and programs
  - Verify: test -d home/modules/terminal && test -d home/modules/cli && test -d home/modules/programs && nix build .#checks.x86_64-linux.home && nix build .#checks.x86_64-linux.layout
  - Arch: Module Seams
  - Seam: `home/modules/{terminal,cli,programs}/`, `tests/home.nix`, `AGENTS.md`.
  - Behavior: Interactive shell and multiplexers move to `terminal/` (`zsh`, `starship`, `tmux`, `zoxide`, `direnv`); headless tools move to `cli/` (`git`, `lazygit`, `bat`, `btop`, `yazi`, `fastfetch`, `tealdeer`, `gpg`, `ssh`, `utilities`); GUI apps, editors, and AI harnesses remain in `programs/`; `import-tree` discovers all modules without configuration breakage.
  - Failures: broken file paths in `tests/home.nix`, missing dependencies, syntax regressions.

- [x] S56 [R23] [D61]: OMP module provides `programs.omp.enable`, generates `~/.omp/agent/` config, skills, agents, and hooks, and builds activation package
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Arch: Framework & Library Choices
  - Seam: `flake.nix`, `flake/default.nix`, `home/modules/programs/omp.nix`, `home/modules/ai/hooks.nix`.
  - Behavior: `programs.omp.enable = true` installs `omp` package, registers `inputs.omp.homeManagerModules.default`, deploys skills into `~/.omp/agent/skills/`, writes agent markdown files into `~/.omp/agent/agents/`, renders disciplines into `SYSTEM.md`, and connects pre-tool and session-start hooks.
  - Failures: flake input resolution errors, broken HM module imports, missing package outputs, invalid activation package.

- [x] S57 [R24] [D62]: Pi built-in extension exclusions
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.pi-coding-agent.settings.extensions && nix build .#checks.x86_64-linux.home
  - Arch: Framework & Library Choices
  - Seam: `home/modules/programs/pi-coding-agent.nix`, `tests/home.nix`.
  - Behavior: `programs.pi-coding-agent.settings.extensions` specifies `["-builtin:tool-search" "-builtin:mcp" "-builtin:llama.cpp"]`; Home Manager renders this into `~/.pi/agent/settings.json`; tests in `tests/home.nix` assert grep matches.
  - Failures: invalid JSON syntax, missing extension override syntax, broken eval.

- [x] S58 [R25] [D63]: Noctalia builtin Hyprland template and wallpaper hook
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.noctalia.settings.theme.templates.builtin_ids | grep -q '"hyprland"' && grep -q wallust "$(nix eval --raw .#homeConfigurations.hollowheap.config.programs.noctalia.settings.hooks.wallpaper_changed)"
  - Arch: Framework & Library Choices
  - Seam: `home/modules/programs/noctalia.nix`, `home/modules/programs/hyprland/hyprland.nix`, `pkgs/mactahoe-icon-accent.py`.
  - Behavior: Noctalia's builtin `hyprland` template owns `~/.config/hypr/noctalia.lua`; Hyprland's `_var` resolver calls `apply_theme` and maps `m.colors`; the wallpaper hook still runs Wallust for remaining consumers and updates GTK/icon accents.
  - Failures: builtin template omitted, Hyprland color resolver missing, icon theme sync failure.

- [x] S59 [R26] [D64]: Neovim in-buffer diagrams and image support
  - Verify: nix eval --raw '.#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.lazy.plugins."diagram.nvim".setupModule' | grep -q "diagram" && nix build .#checks.x86_64-linux.home
  - Arch: Framework & Library Choices
  - Seam: `home/modules/programs/nvim/diagrams.nix`, `home/modules/programs/nvim.nix`, `flake/default.nix`, `tests/home.nix`.
  - Behavior: `home/modules/programs/nvim/diagrams.nix` exports `image.nvim` (eager start plugin with Kitty protocol and `magick_cli`) and `diagram.nvim` (lazy plugin with markdown/neorg integrations and dark mermaid/plantuml/d2 renderers); registers `<leader>m` bindings for render, clear, and hover; adds CLI tools (`imagemagick`, `mermaid-cli`, `plantuml`, `d2`, `graphviz`) to `programs.nvf.settings.vim.extraPackages`.
  - Failures: unfree license evaluation errors, missing CLI executables, start/opt plugin collision warnings.

### Skills and Workflow

- [x] S60 [R18] [D49]: On-demand retro skill evaluates active session transcript
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.retro.description | grep -q "retrospective" && test -f home/modules/ai/skills.nix
  - Arch: Module Seams
  - Seam: `home/modules/ai/skills.nix`.
  - Behavior: `ai.skills.retro` provides single-session retrospective auditing tool efficiency, failure counts, rule compliance, and winning patterns directly from the active transcript into `artifacts/retro.md`.
  - Failures: missing skill definition, invalid markdown schema.

- [x] S61 [R19] [D50]: Corpus-audit skill ingests compacted transcripts across sessions
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.corpus-audit.description | grep -q "corpus-audit" && test -f home/modules/ai/skills.nix
  - Arch: Module Seams
  - Seam: `home/modules/ai/skills.nix`.
  - Behavior: `ai.skills.corpus-audit` provides cross-session auditing for systemic knowledge amnesia, thinking loops, and prompt waste to feed into `author-harness`.
  - Failures: missing skill definition, invalid markdown schema.
