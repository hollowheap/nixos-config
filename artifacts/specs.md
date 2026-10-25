# Specifications

- [x] S01 [R01] [D01]: NixOS hosts and standalone Home Manager evaluate from one flake | Verify: nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath >/dev/null && nix eval .#nixosConfigurations.lacuna.config.system.build.toplevel.drvPath >/dev/null
  - Seam: flake outputs and host wiring.
  - Behavior: both outputs build from `home/` and `hosts/`.
  - Failures: missing input, missing host, divergent option sets.

- [x] S02 [R02] [D02]: NixOS stays on release-26.05 while Home Manager and user programs use unstable | Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.lib.version | grep -q "26\.05" && nix eval --raw .#nixosConfigurations.lacuna.config.home-manager.users.hollowheap.desktop.nixpkgsVersion | grep -q "26\.11"
  - Seam: package-set split.
  - Behavior: NixOS and Home Manager report different nixpkgs channels.
  - Failures: global pkgs forced stable, missing HM override, mixed drivers.

- [x] S03 [R03] [D03]: Hosts compose one profile, role modules, and explicit traits | Verify: grep -q "profiles/laptop" hosts/lacuna/default.nix && grep -q "roles/server/system" hosts/lacuna/default.nix && test -f hosts/lacuna/hardware.nix
  - Seam: host import list.
  - Behavior: chassis, duty, and capability are separate paths.
  - Failures: two profiles, hidden hardware imports, `config.profile` checks.

- [x] S04 [R04] [D04]: Touch and HDR gate compositor settings through hardware flags | Verify: grep -q "home-manager.sharedModules" hardware/touch.nix && grep -q "home-manager.sharedModules" hardware/hdr.nix && grep -Rq "config.desktop.touch" home/gui && grep -Rq "config.desktop.hdr" home/gui
  - Seam: NixOS hardware traits to Home Manager.
  - Behavior: flags are true only when the host imports the trait.
  - Failures: missing shared module, compositor ignoring the flag.

- [x] S05 [R04] [D05]: Lacuna is Intel-only; acervus composes Intel and Nvidia with PRIME | Verify: grep -q "hybrid-gpu" hosts/acervus/default.nix && ! grep -q "hybrid-gpu" hosts/lacuna/hardware.nix && nix eval .#nixosConfigurations.acervus.config.hardware.nvidia.prime.offload.enable | grep -qx true
  - Seam: graphics hardware traits.
  - Behavior: hybrid offload evaluates on acervus only.
  - Failures: lacuna importing Nvidia, missing PRIME, stale bus IDs.

- [x] S06 [R05] [D06]: Boot integration lives in the top-level `boot/` tree | Verify: for f in grub tpm secure-boot minegrub kernel plymouth; do test -f boot/$f.nix; done && test ! -e modules/boot/boot.nix
  - Seam: boot module boundary.
  - Behavior: hosts import boot components explicitly.
  - Failures: boot code under hardware or modules, missing GRUB/TPM files.

- [x] S07 [R05] [D07]: Lacuna declares LUKS and BTRFS storage with Disko | Verify: test -f hosts/lacuna/disko.nix && nix eval .#nixosConfigurations.lacuna.config.disko.devices.disk.main.type | grep -qx disk
  - Seam: host storage configuration.
  - Behavior: GPT, LUKS, and BTRFS subvolumes evaluate.
  - Failures: missing disko module, unencrypted root, absent subvolumes.

- [x] S08 [R06] [D08]: Lacuna runs Headscale, Vaultwarden, Caddy, and ddclient; acervus does not | Verify: nix eval --json .#nixosConfigurations.lacuna.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[true,true,true,true\]' && nix eval --json .#nixosConfigurations.acervus.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[false,false,false,false\]'
  - Seam: server role composition.
  - Behavior: only lacuna imports the server role.
  - Failures: duplicated services, acervus running the vault.

- [x] S09 [R06] [D09]: Caddy uses internal TLS for loopback names and tailscaled trusts its CA | Verify: grep -q "tls internal" roles/server/system/default.nix && grep -q "SSL_CERT_FILE" roles/server/system/default.nix
  - Seam: loopback TLS and client trust.
  - Behavior: Headscale and Vaultwarden serve internal certs; tailscaled trusts the CA.
  - Failures: ACME attempts on hosts-file names, untrusted CA.

- [x] S10 [R06] [D10]: Sops secrets target lacuna's age key, install via systemd, and Vaultwarden reads its admin env | Verify: grep -q "&lacuna age1cum" .sops.yaml && grep -q "vaultwarden_env" secrets.yaml && grep -q "environmentFile" roles/server/system/default.nix && nix eval .#nixosConfigurations.lacuna.config.sops.useSystemdActivation | grep -qx true
  - Seam: encrypted secrets and service consumption.
  - Behavior: activation writes `/run/secrets`; Vaultwarden reads `ADMIN_TOKEN`.
  - Failures: wrong recipient, missing secret, world-readable file.

- [x] S11 [R07] [D11]: The system keeps Hyprland, UWSM, and the greeter; Home Manager owns user settings | Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Seam: system session versus HM session.
  - Behavior: package and portal stay system-managed.
  - Failures: duplicate compositor, missing greeter, HM owning portals.

- [x] S12 [R08] [D12]: `home/cli` declares shared options and never imports `home/gui` | Verify: ! grep -R "home/gui" home/cli && grep -Rq "launchApp" home/cli && grep -Rq "defaultApps" home/cli
  - Seam: Home Manager tier boundary.
  - Behavior: CLI options are reusable without a graphical session.
  - Failures: GUI leakage into CLI, duplicate option declarations.

- [x] S13 [R08] [D13]: The neutral shortcut catalog renders through Hyprland | Verify: nix eval .#nixosConfigurations.lacuna.config.home-manager.users.hollowheap.desktop.shortcuts --apply 's: (builtins.hasAttr "close-window" s) && (builtins.hasAttr "focus-window-left" s) && (builtins.hasAttr "move-window-to-workspace" s)' | grep -qx true
  - Seam: shared shortcut option and compositor renderer.
  - Behavior: catalog entries become Hyprland binds.
  - Failures: missing action mapping, duplicate keybinds.

- [x] S14 [R09] [D14]: `fovea` evaluates as a nix-on-droid output | Verify: nix eval .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx "24.05" && test ! -d hosts/fovea
  - Seam: Termux flake output.
  - Behavior: the root config evaluates on unstable aarch64.
  - Failures: host enumeration picking up Termux, missing input.

- [x] S15 [R10] [D15]: Flake checks enforce the layout | Verify: nix flake check
  - Seam: flake `checks`.
  - Behavior: profile, role, hardware, boot, Home Manager, and Termux paths are checked.
  - Failures: stale paths, missing files, forbidden loaders.

- [x] S16 [R02] [D16]: Unfree packages are declarable and merge into both package sets | Verify: nix eval .#nixosConfigurations.lacuna.config.unfreePackages --apply 'ps: builtins.elem "steam" ps' | grep -qx true && grep -q "config.unfreePackages" modules/system/nixpkgs.nix
  - Seam: nixpkgs license policy.
  - Behavior: modules append their own unfree names.
  - Failures: hardcoded list, predicate not applied to unstable.

- [x] S17 [R03] [D17]: Admin groups compose from module ownership | Verify: nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.extraGroups | grep -q '"podman"' && nix eval --json .#nixosConfigurations.lacuna.config.users.adminExtraGroups | grep -q '"podman"' && ! grep -q '"podman"' modules/system/users.nix
  - Seam: user group seam.
  - Behavior: Podman, Wi-Fi, RGB, TPM, and graphics modules append groups.
  - Failures: hardcoded groups, missing module ownership.

- [x] S18 [R05] [D18]: Acervus ignores lid close, disables suspend, and has no charge cap | Verify: nix eval .#nixosConfigurations.acervus.config.services.logind.settings.Login.HandleLidSwitch | grep -qx ignore && nix eval .#nixosConfigurations.acervus.config.systemd.sleep.settings.Sleep.AllowSuspend | grep -qx no && ! grep -R "charge_control_end_threshold" hosts/acervus
  - Seam: host power policy.
  - Behavior: the server stays awake with the lid closed.
  - Failures: suspend on AC, battery cap reintroduced.

- [x] S19 [R06] [D19]: Vaultwarden reads `ADMIN_TOKEN` from sops | Verify: nix eval --json .#nixosConfigurations.lacuna.config.services.vaultwarden.environmentFile | grep -q "/run/secrets/vaultwarden_env" && grep -q "vaultwarden_env:" secrets.yaml
  - Seam: Vaultwarden admin configuration.
  - Behavior: the admin panel is enabled without plaintext secrets.
  - Failures: missing env file, token in git.

- [x] S20 [R08] [D20]: The visual baseline evaluates and renders under Hyprland | Verify: nix eval .#homeConfigurations.hollowheap.config.gtk.theme.name >/dev/null && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Seam: Home Manager visual options.
  - Behavior: theme, fonts, cursor, icons, Hyprland appearance, and Noctalia evaluate.
  - Failures: missing theme, unresolved package, absent Noctalia config.

- [ ] S21 [R11] [D21]: Optional apps live in `home/apps/<bundle>` and stay out of the CLI baseline | Verify: test -f home/apps/gaming/prismlauncher.nix && ! grep -R "prismlauncher" home/cli
  - Seam: app bundle boundary.
  - Behavior: gaming and GUI apps are explicit imports.
  - Failures: PrismLauncher in CLI, missing bundle.

- [ ] S22 [R12] [D22]: Caddy can issue publicly trusted certs via DuckDNS DNS-01 | Verify: grep -q "dns duckdns" roles/server/system/default.nix
  - Seam: Caddy certificate issuance.
  - Behavior: DNS-01 replaces internal TLS when public trust is needed.
  - Failures: ACME port exposure, missing DuckDNS token.

- [ ] S23 [R13] [D23]: User identity is sops-backed and immutable | Verify: nix eval .#nixosConfigurations.lacuna.config.users.users.hollowheap.hashedPasswordFile >/dev/null
  - Seam: user account configuration.
  - Behavior: passwords and SSH keys come from secrets.
  - Failures: imperative `passwd`, missing hashed password.

- [ ] S24 [R14] [D24]: Additional hyprgrass gestures cover window and launcher actions | Verify: grep -q 'kind = "longpress"' home/gui/touch.nix
  - Seam: touch compositor module.
  - Behavior: long-press and multi-finger gestures map to native actions.
  - Failures: gesture conflicts, unsupported action names.

- [x] S25 [R05] [D25]: GRUB and Minegrub use a 3-second timeout | Verify: nix eval .#nixosConfigurations.lacuna.config.boot.loader.timeout | grep -qx 3 && grep -q "set timeout=3" pkgs/double-minegrub-menu.nix
  - Seam: bootloader wait time.
  - Behavior: both the loader and theme menu wait three seconds.
  - Failures: packaged timeout remains 15 seconds, loader differs.

- [x] S26 [R04] [D26]: Intel graphics use early i915 KMS and fastboot | Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.kernelModules | grep -q '"i915"' && nix eval .#nixosConfigurations.lacuna.config.boot.kernelParams | grep -q 'i915.fastboot=1'
  - Seam: Intel graphics hardware trait.
  - Behavior: i915 initializes early and preserves the GOP framebuffer.
  - Failures: late KMS, missing fastboot, panel reinitialization.

- [x] S27 [R05] [D27]: TPM2 unlock and PCR measurement run in systemd initrd | Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.tpm2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.boot.initrd.luks.devices.crypted.crypttabExtraOpts | grep -q "tpm2-device=auto"
  - Seam: encrypted boot.
  - Behavior: the LUKS device unlocks with TPM2 and measures PCRs.
  - Failures: missing tpm_tis, passphrase-only boot, unmeasured unlock.

- [x] S28 [R05] [D28]: Secure Boot install hooks sign GRUB and kernels with sbctl | Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.extraInstallCommands | grep -q sbctl
  - Seam: bootloader signing.
  - Behavior: GRUB and kernels are signed during install.
  - Failures: unsigned binaries, missing sbctl, wrong EFI path.

- [x] S29 [R05] [D29]: Minegrub packages stay in pkgs and theme selection stays in boot | Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.theme.name | grep -q double-minegrub-menu && test ! -e hardware/minegrub.nix
  - Seam: boot theme selection.
  - Behavior: the theme package and mainmenu redirection evaluate.
  - Failures: hardware minegrub module, missing package, broken menu path.

- [x] S30 [R06] [D30]: PipeWire provides ALSA and PulseAudio compatibility | Verify: nix eval .#nixosConfigurations.lacuna.config.services.pipewire.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.pipewire.pulse.enable | grep -qx true
  - Seam: desktop audio stack.
  - Behavior: 32-bit ALSA and PulseAudio clients share PipeWire.
  - Failures: missing ALSA support, no PulseAudio bridge.

- [x] S31 [R06] [D31]: systemd-resolved uses Cloudflare DNS-over-TLS | Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.resolved.extraConfig | grep -q "security.cloudflare-dns.com"
  - Seam: DNS resolution.
  - Behavior: upstream queries use DNS-over-TLS.
  - Failures: plaintext DNS, wrong resolver, no TLS.

- [x] S32 [R06] [D32]: NetworkManager uses iwd and sops-backed Wi-Fi profiles | Verify: nix eval --raw .#nixosConfigurations.lacuna.config.networking.networkmanager.wifi.backend | grep -qx iwd && grep -q "wireless_env" hardware/wifi.nix
  - Seam: wireless networking.
  - Behavior: iwd manages Wi-Fi and profiles read encrypted credentials.
  - Failures: wpa_supplicant backend, missing secret, invalid profile.

- [x] S33 [R06] [D33]: Removable media and iOS devices work through desktop daemons | Verify: nix eval .#nixosConfigurations.lacuna.config.services.udisks2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.gvfs.enable | grep -qx true
  - Seam: desktop device services.
  - Behavior: file managers can mount media and access iOS devices.
  - Failures: missing gvfs, no usbmuxd, root-only mounts.

- [x] S34 [R05] [D34]: Laptop thermal and power policy lives in the laptop profile | Verify: nix eval .#nixosConfigurations.lacuna.config.services.thermald.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.upower.enable | grep -qx true
  - Seam: chassis policy.
  - Behavior: thermald, upower, and power-profiles-daemon are enabled.
  - Failures: hardware trait owning policy, missing services.

- [x] S35 [R01] [D35]: Recursive module discovery remains in lib | Verify: grep -q "mkModuleLoader" modules/default.nix && test -f lib/default.nix
  - Seam: module loading.
  - Behavior: `modules/default.nix` discovers all module files.
  - Failures: manual import drift, missing loader.

- [x] S36 [R01] [D36]: The package overlay discovers local derivations | Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.double-minegrub-menu.name | grep -q double-minegrub-menu && grep -q "kebabToCamel" pkgs/default.nix
  - Seam: local package overlay.
  - Behavior: local files resolve through `overlays.default`.
  - Failures: missing package, broken directory scope.

- [x] S37 [R01] [D37]: Every language devShell and alias evaluates | Verify: for s in default ts c rust python pico nix typescript js clang cpp; do nix eval .#devShells.x86_64-linux.$s.name >/dev/null || exit 1; done
  - Seam: flake devShells.
  - Behavior: language shells and aliases resolve on unstable.
  - Failures: missing shell, stale alias.

- [x] S38 [R06] [D38]: Cachix substituters are trusted alongside the NixOS cache | Verify: nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "nix-on-droid.cachix.org" && nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "hyprland.cachix.org"
  - Seam: binary cache policy.
  - Behavior: Termux, community, and Hyprland caches are trusted.
  - Failures: missing key, untrusted cache.

- [x] S39 [R06] [D39]: Server ingress ports live with the Headscale role | Verify: grep -q "Headscale ingress" roles/server/system/default.nix && grep -q "allowedUDPPorts = \[ 3478 \]" roles/server/system/default.nix
  - Seam: server firewall configuration.
  - Behavior: Caddy and Headscale own ports 80/443 and 3478.
  - Failures: ports in a generic module, client opening server ports.

- [x] S40 [R05] [D40]: BTRFS scrub, zram, and mount policy are enabled | Verify: nix eval .#nixosConfigurations.lacuna.config.services.btrfs.autoScrub.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.zramSwap.enable | grep -qx true
  - Seam: filesystem policy.
  - Behavior: monthly scrub, zram swap, and explicit mount options evaluate.
  - Failures: missing scrub, no zram, lost mount options.

- [x] S41 [R15] [D41]: Domain checks live in `tests/` and load automatically | Verify: nix build .#checks.x86_64-linux.layout .#checks.x86_64-linux.policy .#checks.x86_64-linux.hardware .#checks.x86_64-linux.home .#checks.x86_64-linux.services .#checks.x86_64-linux.users
  - Seam: flake `checks` output and `tests/` loader.
  - Behavior: each `tests/<domain>.nix` becomes `checks.x86_64-linux.<domain>`.
  - Failures: loader misses a file, duplicate domain name, check build error.

- [x] S42 [R16] [D42]: The CLI baseline evaluates a shell and terminal toolset independently of the GUI tier | Verify: test -f home/cli/zsh.nix && nix eval .#homeConfigurations.hollowheap.config.programs.zsh.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.programs.eza.enable | grep -qx true
  - Seam: `home/cli` import root.
  - Behavior: zsh, zoxide, git, direnv, tealdeer, and core terminal tools resolve.
  - Failures: missing module, GUI dependency, duplicate option.

- [ ] S43 [R17] [D43]: Remaining Home Manager slices evaluate before parity is claimed | Verify: test -f home/cli/starship.nix && test -f home/apps/gui/ghostty.nix && test -f home/cli/opencode.nix
  - Seam: Home Manager module parity.
  - Behavior: prompt theming, GUI apps, editor/AI, and auxiliary services land as separate slices.
  - Failures: treating infrastructure tasks as feature parity.
