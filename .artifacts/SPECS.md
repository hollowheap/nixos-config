# Specifications

### System Foundation

#### System Shape

- [x] S01 [R01] [D01]: NixOS hosts and standalone Home Manager evaluate from one flake
  - Verify: nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath >/dev/null && nix eval .#nixosConfigurations.lacuna.config.system.build.toplevel.drvPath >/dev/null
  - Seam: flake outputs and host wiring.
  - Behavior: both outputs build from `home/` and `hosts/`.
  - Failures: missing input, missing host, divergent option sets.
  - Ledger: tests/S01.md

- [x] S02 [R02] [D02]: NixOS stays on release-26.05 while standalone Home Manager and user programs use unstable
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.lib.version | grep -q "26\.05" && nix eval --raw .#homeConfigurations.hollowheap.pkgs.lib.version | grep -q "26\.11"
  - Seam: package-set split.
  - Behavior: NixOS and Home Manager report different nixpkgs channels.
  - Failures: global pkgs forced stable, missing HM override, mixed drivers.
  - Ledger: tests/S02.md

- [x] S03 [R03] [D03]: Hosts compose one profile, role modules, and explicit traits
  - Verify: grep -q "profiles/laptop" hosts/lacuna/default.nix && grep -q "roles/server/system" hosts/lacuna/default.nix && test -f hosts/lacuna/hardware.nix
  - Seam: host import list.
  - Behavior: chassis, duty, and capability are separate paths.
  - Failures: two profiles, hidden hardware imports, `config.profile` checks.
  - Ledger: tests/S03.md

- [x] S04 [R04] [D04]: Touch and HDR gate compositor settings through hardware flags
  - Verify: grep -q "desktop.touch = true" hardware/touch.nix && grep -q "desktop.hdr = true" hardware/hdr.nix && grep -q "desktop.touch = true" home/hollowheap.nix && grep -Rq "config.desktop.touch" home/modules/environment
  - Seam: hardware traits and the standalone Home Manager config.
  - Behavior: lacuna's standalone HM sets both flags; compositor modules gate on them.
  - Failures: hardware trait missing, standalone config not enabling the flag, compositor ignoring it.
  - Ledger: tests/S04.md

- [x] S05 [R04] [D05]: Lacuna is Intel-only; acervus composes Intel and Nvidia with PRIME
  - Verify: grep -q "hybrid-gpu" hosts/acervus/default.nix && ! grep -q "hybrid-gpu" hosts/lacuna/hardware.nix && nix eval .#nixosConfigurations.acervus.config.hardware.nvidia.prime.offload.enable | grep -qx true
  - Seam: graphics hardware traits.
  - Behavior: hybrid offload evaluates on acervus only.
  - Failures: lacuna importing Nvidia, missing PRIME, stale bus IDs.
  - Ledger: tests/S05.md

- [x] S06 [R05] [D06]: Boot integration lives in the top-level `boot/` tree
  - Verify: for f in grub tpm secure-boot minegrub kernel plymouth; do test -f boot/$f.nix; done && test ! -e modules/boot/boot.nix
  - Seam: boot module boundary.
  - Behavior: hosts import boot components explicitly.
  - Failures: boot code under hardware or modules, missing GRUB/TPM files.
  - Ledger: tests/S06.md

- [x] S07 [R05] [D07]: Lacuna declares LUKS and BTRFS storage with Disko
  - Verify: test -f hosts/lacuna/disko.nix && nix eval .#nixosConfigurations.lacuna.config.disko.devices.disk.main.type | grep -qx disk
  - Seam: host storage configuration.
  - Behavior: GPT, LUKS, and BTRFS subvolumes evaluate.
  - Failures: missing disko module, unencrypted root, absent subvolumes.
  - Ledger: tests/S07.md

- [x] S08 [R06] [D08]: Lacuna runs Headscale, Vaultwarden, Caddy, and ddclient; acervus does not
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[true,true,true,true\]' && nix eval --json .#nixosConfigurations.acervus.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[false,false,false,false\]'
  - Seam: server role composition.
  - Behavior: only lacuna imports the server role.
  - Failures: duplicated services, acervus running the vault.
  - Ledger: tests/S08.md

- [x] S11 [R07] [D11]: The system keeps Hyprland, UWSM, and the greeter; Home Manager owns user settings
  - Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Seam: system session versus HM session.
  - Behavior: package and portal stay system-managed.
  - Failures: duplicate compositor, missing greeter, HM owning portals.
  - Ledger: tests/S11.md

- [x] S14 [R09] [D14]: `fovea` evaluates as a nix-on-droid output
  - Verify: nix eval .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx "24.05" && test ! -d hosts/fovea
  - Seam: Termux flake output.
  - Behavior: the root config evaluates on unstable aarch64.
  - Failures: host enumeration picking up Termux, missing input.
  - Ledger: tests/S14.md

#### Operations & Security

- [x] S09 [R06] [D116]: Caddy uses internal TLS for loopback names and tailscaled trusts its CA
  - Verify: grep -q "tls internal" roles/server/system/default.nix && grep -q "SSL_CERT_FILE" roles/server/system/default.nix
  - Seam: loopback TLS and client trust.
  - Behavior: Headscale and Vaultwarden serve internal certs; tailscaled trusts the CA.
  - Failures: ACME attempts on hosts-file names, untrusted CA.
  - Ledger: tests/S09.md

- [x] S10 [R06] [D70]: Sops secrets target lacuna's age key, install via systemd, and Vaultwarden reads its admin env
  - Verify: grep -q "&lacuna age1cum" .sops.yaml && grep -q "vaultwarden_env" secrets.yaml && grep -q "environmentFile" roles/server/system/default.nix && nix eval .#nixosConfigurations.lacuna.config.sops.useSystemdActivation | grep -qx true
  - Seam: encrypted secrets and service consumption.
  - Behavior: activation writes `/run/secrets`; Vaultwarden reads `ADMIN_TOKEN`.
  - Failures: wrong recipient, missing secret, world-readable file.
  - Ledger: tests/S10.md

#### Module Seams

- [x] S12 [R08] [D46]: Home Manager modules load recursively through `import-tree` with no central module list
  - Verify: grep -q "import-tree ./modules" home/hollowheap.nix && ! test -e home/cli.nix && ! test -e home/gui.nix
  - Seam: Home Manager module discovery.
  - Behavior: `home/modules` loads without cli/gui entrypoints; per-user files only set identity and options.
  - Failures: central import lists, missing modules, duplicate option declarations.
  - Ledger: tests/S12.md

- [x] S13 [R08] [D13]: The neutral shortcut catalog renders through Hyprland
  - Verify: nix eval .#homeConfigurations.hollowheap.config.desktop.shortcuts --apply 's: (builtins.hasAttr "close-window" s) && (builtins.hasAttr "focus-window-left" s) && (builtins.hasAttr "move-window-to-workspace" s)' | grep -qx true
  - Seam: shared shortcut option and compositor renderer.
  - Behavior: catalog entries become Hyprland binds.
  - Failures: missing action mapping, duplicate keybinds.
  - Ledger: tests/S13.md

- [x] S15 [R10] [D15]: Flake checks enforce the layout
  - Verify: nix flake check
  - Seam: flake `checks`.
  - Behavior: profile, role, hardware, boot, Home Manager, and Termux paths are checked.
  - Failures: stale paths, missing files, forbidden loaders.
  - Ledger: tests/S15.md

- [x] S17 [R03] [D17]: Admin groups compose from module ownership
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.extraGroups | grep -q '"podman"' && nix eval --json .#nixosConfigurations.lacuna.config.users.adminExtraGroups | grep -q '"podman"' && ! grep -q '"podman"' modules/system/users.nix
  - Seam: user group seam.
  - Behavior: Podman, Wi-Fi, RGB, TPM, and graphics modules append groups.
  - Failures: hardcoded groups, missing module ownership.
  - Ledger: tests/S17.md

#### Data & Contracts

- [x] S16 [R02] [D16]: Unfree packages are declarable and merge into both package sets
  - Verify: nix eval .#nixosConfigurations.lacuna.config.unfreePackages --apply 'ps: builtins.elem "steam" ps' | grep -qx true && grep -q "config.unfreePackages" modules/system/nixpkgs.nix
  - Seam: nixpkgs license policy.
  - Behavior: modules append their own unfree names.
  - Failures: hardcoded list, predicate not applied to unstable.
  - Ledger: tests/S16.md

### Host Infrastructure

#### System Shape

- [x] S18 [R05] [D18]: Acervus ignores lid close, disables suspend, and has no charge cap
  - Verify: nix eval .#nixosConfigurations.acervus.config.services.logind.settings.Login.HandleLidSwitch | grep -qx ignore && nix eval .#nixosConfigurations.acervus.config.systemd.sleep.settings.Sleep.AllowSuspend | grep -qx no && ! grep -R "charge_control_end_threshold" hosts/acervus
  - Seam: host power policy.
  - Behavior: the server stays awake with the lid closed.
  - Failures: suspend on AC, battery cap reintroduced.
  - Ledger: tests/S18.md

- [x] S25 [R05] [D25]: GRUB and Minegrub use a 3-second timeout
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.loader.timeout | grep -qx 3 && grep -q "set timeout=3" pkgs/double-minegrub-menu.nix
  - Seam: bootloader wait time.
  - Behavior: both the loader and theme menu wait three seconds.
  - Failures: packaged timeout remains 15 seconds, loader differs.
  - Ledger: tests/S25.md

- [x] S26 [R04] [D26]: Intel graphics use early i915 KMS and fastboot
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.kernelModules | grep -q '"i915"' && nix eval .#nixosConfigurations.lacuna.config.boot.kernelParams | grep -q 'i915.fastboot=1'
  - Seam: Intel graphics hardware trait.
  - Behavior: i915 initializes early and preserves the GOP framebuffer.
  - Failures: late KMS, missing fastboot, panel reinitialization.
  - Ledger: tests/S26.md

- [x] S27 [R05] [D27]: TPM2 unlock and PCR measurement run in systemd initrd
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.tpm2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.boot.initrd.luks.devices.crypted.crypttabExtraOpts | grep -q "tpm2-device=auto"
  - Seam: encrypted boot.
  - Behavior: the LUKS device unlocks with TPM2 and measures PCRs.
  - Failures: missing tpm_tis, passphrase-only boot, unmeasured unlock.
  - Ledger: tests/S27.md

- [x] S29 [R05] [D29]: Minegrub packages stay in pkgs and theme selection stays in boot
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.theme.name | grep -q double-minegrub-menu && test ! -e hardware/minegrub.nix
  - Seam: boot theme selection.
  - Behavior: the theme package and mainmenu redirection evaluate.
  - Failures: hardware minegrub module, missing package, broken menu path.
  - Ledger: tests/S29.md

- [x] S34 [R05] [D34]: Laptop thermal and power policy lives in the laptop profile
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.thermald.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.upower.enable | grep -qx true
  - Seam: chassis policy.
  - Behavior: thermald, upower, and power-profiles-daemon are enabled.
  - Failures: hardware trait owning policy, missing services.
  - Ledger: tests/S34.md

#### Data & Contracts

- [x] S19 [R06] [D19]: Vaultwarden reads `ADMIN_TOKEN` from sops
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services.vaultwarden.environmentFile | grep -q "/run/secrets/vaultwarden_env" && grep -q "vaultwarden_env:" secrets.yaml
  - Seam: Vaultwarden admin configuration.
  - Behavior: the admin panel is enabled without plaintext secrets.
  - Failures: missing env file, token in git.
  - Ledger: tests/S19.md

- [ ] S23 [R13] [D23]: User identity is sops-backed and immutable
  - Verify: nix eval .#nixosConfigurations.lacuna.config.users.users.hollowheap.hashedPasswordFile >/dev/null
  - Seam: user account configuration.
  - Behavior: passwords and SSH keys come from secrets.
  - Failures: imperative `passwd`, missing hashed password.
  - Ledger: tests/S23.md

#### Framework & Library Choices

- [x] S20 [R08] [D20]: The visual baseline evaluates and renders under Hyprland
  - Verify: nix eval .#homeConfigurations.hollowheap.config.gtk.theme.name >/dev/null && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Seam: Home Manager visual options.
  - Behavior: theme, fonts, cursor, icons, Hyprland appearance, and Noctalia evaluate.
  - Failures: missing theme, unresolved package, absent Noctalia config.
  - Ledger: tests/S20.md

- [x] S30 [R06] [D30]: PipeWire provides ALSA and PulseAudio compatibility
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.pipewire.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.pipewire.pulse.enable | grep -qx true
  - Seam: desktop audio stack.
  - Behavior: 32-bit ALSA and PulseAudio clients share PipeWire.
  - Failures: missing ALSA support, no PulseAudio bridge.
  - Ledger: tests/S30.md
- [ ] S101 [R06] [D111]: Acervus installation is available as a squashfs image
  - Verify: `nix eval --raw '.#apps.x86_64-linux.install-acervus.program' >/dev/null && nix build .#images.acervus --dry-run >/dev/null`
  - Seam: flake/default.nix, hosts/acervus/*, pkgs/install-host.nix, nix-on-droid.nix.
  - Behavior: A fresh installer image can run disko and install the host without a prebuilt machine..
  - Failures: Installer exists only as a script, no reproducible image output..
  - Ledger: tests/S101.md

#### Module Seams

- [x] S21 [R11] [D21]: Optional apps live in `home/modules/programs/gaming` and stay out of the CLI baseline
  - Verify: test -f home/modules/programs/gaming/prismlauncher.nix && ! grep -R "prismlauncher" home/modules/programs/default.nix
  - Seam: app bundle boundary.
  - Behavior: gaming and GUI apps are explicit imports.
  - Failures: PrismLauncher in CLI, missing bundle.
  - Ledger: tests/S21.md

- [x] S24 [R14] [D24]: Additional hyprgrass gestures cover window and launcher actions
  - Verify: grep -q 'kind = "longpress"' home/modules/environment/touch.nix
  - Seam: touch compositor module.
  - Behavior: long-press and multi-finger gestures map to native actions.
  - Failures: gesture conflicts, unsupported action names.
  - Ledger: tests/S24.md

- [x] S35 [R01] [D35]: Recursive module discovery remains in lib
  - Verify: grep -q "mkModuleLoader" modules/default.nix && test -f lib/default.nix
  - Seam: module loading.
  - Behavior: `modules/default.nix` discovers all module files.
  - Failures: manual import drift, missing loader.
  - Ledger: tests/S35.md

- [x] S36 [R01] [D36]: The package overlay discovers local derivations
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.double-minegrub-menu.name | grep -q double-minegrub-menu && grep -q "kebabToCamel" pkgs/default.nix
  - Seam: local package overlay.
  - Behavior: local files resolve through `overlays.default`.
  - Failures: missing package, broken directory scope.
  - Ledger: tests/S36.md

- [x] S37 [R01] [D37]: Every language devShell and alias evaluates
  - Verify: for s in default ts c rust python pico nix typescript js clang cpp; do nix eval .#devShells.x86_64-linux.$s.name >/dev/null || exit 1; done
  - Seam: flake devShells.
  - Behavior: language shells and aliases resolve on unstable.
  - Failures: missing shell, stale alias.
  - Ledger: tests/S37.md

#### Operations & Security

- [x] S22 [R12] [D116]: Caddy can issue publicly trusted certs via DuckDNS DNS-01
  - Verify: grep -q "dns duckdns" roles/server/system/default.nix
  - Seam: Caddy certificate issuance.
  - Behavior: DNS-01 replaces internal TLS when public trust is needed.
  - Failures: ACME port exposure, missing DuckDNS token.
  - Ledger: tests/S22.md

- [x] S28 [R05] [D28]: Secure Boot install hooks sign GRUB and kernels with sbctl
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.extraInstallCommands | grep -q sbctl
  - Seam: bootloader signing.
  - Behavior: GRUB and kernels are signed during install.
  - Failures: unsigned binaries, missing sbctl, wrong EFI path.
  - Ledger: tests/S28.md

- [x] S31 [R06] [D31]: systemd-resolved uses Cloudflare DNS-over-TLS
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.resolved.extraConfig | grep -q "security.cloudflare-dns.com"
  - Seam: DNS resolution.
  - Behavior: upstream queries use DNS-over-TLS.
  - Failures: plaintext DNS, wrong resolver, no TLS.
  - Ledger: tests/S31.md

- [x] S32 [R06] [D32]: NetworkManager uses iwd and sops-backed Wi-Fi profiles
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.networking.networkmanager.wifi.backend | grep -qx iwd && grep -q "wireless_env" hardware/wifi.nix
  - Seam: wireless networking.
  - Behavior: iwd manages Wi-Fi and profiles read encrypted credentials.
  - Failures: wpa_supplicant backend, missing secret, invalid profile.
  - Ledger: tests/S32.md

- [x] S33 [R06] [D33]: Removable media and iOS devices work through desktop daemons
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.udisks2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.gvfs.enable | grep -qx true
  - Seam: desktop device services.
  - Behavior: file managers can mount media and access iOS devices.
  - Failures: missing gvfs, no usbmuxd, root-only mounts.
  - Ledger: tests/S33.md

- [x] S38 [R06] [D38]: Cachix substituters are trusted alongside the NixOS cache
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "nix-on-droid.cachix.org" && nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "hyprland.cachix.org"
  - Seam: binary cache policy.
  - Behavior: Termux, community, and Hyprland caches are trusted.
  - Failures: missing key, untrusted cache.
  - Ledger: tests/S38.md

- [x] S39 [R06] [D39]: Server ingress ports live with the Headscale role
  - Verify: grep -q "Headscale ingress" roles/server/system/default.nix && grep -q "allowedUDPPorts = \[ 3478 \]" roles/server/system/default.nix
  - Seam: server firewall configuration.
  - Behavior: Caddy and Headscale own ports 80/443 and 3478.
  - Failures: ports in a generic module, client opening server ports.
  - Ledger: tests/S39.md

- [x] S40 [R05] [D40]: BTRFS scrub, zram, and mount policy are enabled
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.btrfs.autoScrub.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.zramSwap.enable | grep -qx true
  - Seam: filesystem policy.
  - Behavior: monthly scrub, zram swap, and explicit mount options evaluate.
  - Failures: missing scrub, no zram, lost mount options.
  - Ledger: tests/S40.md
- [ ] S72 [R56] [D70]: Shared secrets decrypt on both hosts while server-only secrets stay restricted
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.sops.secrets --apply 's: s ? vaultwarden_env && s ? wireless_env' | grep -qx true && nix eval --json .#nixosConfigurations.acervus.config.sops.secrets --apply 's: !(s ? vaultwarden_env) && s ? wireless_env' | grep -qx true`
  - Seam: secrets/secrets.yaml, modules/security/sops.nix, hosts/lacuna/default.nix, hosts/acervus/default.nix, .sops.yaml.
  - Behavior: Host secret scope matches host duty; a non-server cannot decrypt server credentials..
  - Failures: One encrypted blob shared by both hosts, missing recipient, leaked server secret..
  - Ledger: tests/S72.md

- [ ] S82 [R33] [D92]: Stay-awake behavior owns lid-close policy; stale suspend assertions are gone
  - Verify: `! rg -q 'HandleLidSwitch' profiles/laptop/default.nix tests/policy.nix && rg -q 'caffeine' home/modules/programs/noctalia.nix`
  - Seam: profiles/laptop/default.nix, tests/policy.nix, home/modules/programs/noctalia.nix.
  - Behavior: Active stay-awake prevents suspend; no split logind policy remains..
  - Failures: Stale suspend assertion, inhibitor coordination hidden in NixOS layer..
  - Ledger: tests/S82.md

- [x] S100 [R12] [D110]: HTTPS ingress remains unchanged while the routing decision is open
  - Verify: `rg -q 'tls internal' roles/server/system/headscale.nix roles/server/system/vaultwarden.nix && ! rg -q 'tailscale cert' roles/server/system flake`
  - Seam: roles/server/system/caddy.nix, roles/server/system/headscale.nix, roles/server/system/vaultwarden.nix, roles/server/system/default.nix.
  - Behavior: No WAN exposure or Tailscale certificate dependency is introduced by this pass..
  - Failures: Premature ingress rewrite, untrusted client CA, WAN port opening..
  - Ledger: tests/S100.md

- [ ] S102 [R13] [D112]: Declarative identity uses the GPG auth subkey public credential
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.users.mutableUsers | jq -e '. == false' && nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.openssh.authorizedKeys.keys | jq -e 'any(.[]; startswith("ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmWse"))'`
  - Seam: modules/system/users.nix.
  - Behavior: The host accepts the GPG-derived SSH key and rejects imperative user drift..
  - Failures: Wrong key, mutable users, lockout after rebuild..
  - Ledger: tests/S102.md

- [x] S104 [R12] [D116]: Handheld HTTPS access stays unchanged until the server moves
  - Verify: `rg -q 'tls internal' roles/server/system/headscale.nix && rg -q 'SSL_CERT_FILE' roles/server/system/default.nix && nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx 24.05`
  - Seam: roles/server/system/default.nix, roles/server/system/headscale.nix, nix-on-droid.nix.
  - Behavior: No temporary mesh-pin or WAN forwarding workaround is introduced..
  - Failures: Fovea TLS changed before acervus exists, DNS pinned to wrong host..
  - Ledger: tests/S104.md

- [ ] S105 [R06] [D117]: Installer secrets use throwaway credentials that never enter git or the target
  - Verify: `! rg -q -i 'PRIVATE KEY' flake.nix pkgs/install-host.nix && rg -q 'ephemeral|throwaway|age' pkgs/install-host.nix`
  - Seam: flake/default.nix, pkgs/install-host.nix, hosts/acervus/*.
  - Behavior: A rebuilt ISO can install without committing or persisting the operator private key..
  - Failures: Private key committed, ISO bakes long-lived secret, target retains installer key..
  - Ledger: tests/S105.md

### Modules and Checks

#### Module Seams

- [x] S41 [R15] [D74]: Domain checks live in `tests/` and load automatically
  - Verify: nix build .#checks.x86_64-linux.layout .#checks.x86_64-linux.policy .#checks.x86_64-linux.hardware .#checks.x86_64-linux.home .#checks.x86_64-linux.services .#checks.x86_64-linux.users
  - Seam: flake `checks` output and `tests/` loader.
  - Behavior: each `tests/<domain>.nix` becomes `checks.x86_64-linux.<domain>`.
  - Failures: loader misses a file, duplicate domain name, check build error.
  - Ledger: tests/S41.md

- [x] S42 [R16] [D42]: The CLI baseline evaluates a shell and terminal toolset independently of the GUI tier
  - Verify: test -f home/modules/terminal/zsh.nix && nix eval .#homeConfigurations.hollowheap.config.programs.zsh.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.programs.eza.enable | grep -qx true
  - Seam: `home/modules` import-tree root.
  - Behavior: zsh, zoxide, git, direnv, tealdeer, and core terminal tools resolve.
  - Failures: missing module, GUI dependency, duplicate option.
  - Ledger: tests/S42.md

- [x] S43 [R17] [D43]: Remaining Home Manager slices evaluate before parity is claimed
  - Verify: test -f home/modules/terminal/starship.nix && test -f home/modules/programs/gui/ghostty.nix && test -f home/modules/programs/opencode.nix
  - Seam: Home Manager module parity.
  - Behavior: prompt theming, GUI apps, editor/AI, and auxiliary services land as separate slices.
  - Failures: treating infrastructure tasks as feature parity.
  - Ledger: tests/S43.md

- [x] S44 [R08] [D46]: Shared desktop values drive Hyprland and the greeter
  - Verify: grep -q "primaryScale" modules/options/desktop.nix && grep -q "config.desktop.primaryScale" home/modules/programs/hyprland/hyprland.nix && grep -q "config.desktop.primaryScale" roles/desktop/system/default.nix
  - Seam: shared desktop data.
  - Behavior: monitor layout, primary output, scale, and font families have one source; Hyprland and Noctalia wire it independently.
  - Failures: duplicated scale constants, greeter drifting from compositor, font values duplicated across modules.
  - Ledger: tests/S44.md

- [x] S45 [R08] [D47]: Hyprland keybinds are a reusable compositor module
  - Verify: test -f home/modules/programs/hyprland/keybinds.nix && grep -q "../../../lib/hyprland.nix" home/modules/programs/hyprland/keybinds.nix && ! grep -q "bind = map mkArgs" home/modules/programs/hyprland/hyprland.nix
  - Seam: compositor interaction policy.
  - Behavior: binds and submaps load from one module; host modules provide monitors, plugins, and window rules separately.
  - Failures: duplicated bind tables, helpers drift, keybinds missing from a host.
  - Ledger: tests/S45.md

- [x] S46 [R08] [D48]: Compositor window dimensions are neutral options, not theme or Hyprland-specific data
  - Verify: test -f home/modules/environment/compositor.nix && grep -q "desktop.compositor" home/modules/environment/compositor.nix && grep -q "config.desktop.compositor" home/modules/programs/hyprland/hyprland.nix
  - Seam: compositor geometry.
  - Behavior: gaps, borders, radius, and bar height come from `desktop.compositor`; Hyprland and Noctalia consume them.
  - Failures: dimensions under `styles`, duplicated values, program-specific option names.
  - Ledger: tests/S46.md
- [ ] S74 [R15] [D74]: Checks, license policy, and shared helpers are exposed through stable flake seams
  - Verify: `nix eval --raw .#lib >/dev/null && nix eval --json .#homeConfigurations.hollowheap.config.unfreePackages --apply 'ps: builtins.isList ps' | grep -qx true && test -f tests/default.nix`
  - Seam: flake/default.nix, tests/default.nix, modules/system/nixpkgs.nix, home/modules/core/unfree.nix.
  - Behavior: A new domain check or unfree package registers without editing the composition root..
  - Failures: Inline checks shadow tests/, hardcoded license list, missing outputs.lib..
  - Ledger: tests/S74.md

- [ ] S75 [R53] [D75]: The shell receives EOF on Ctrl-D while the popup stays behind the prefix
  - Verify: `rg -q '^bind d ' home/modules/terminal/tmux.nix && ! rg -q '^bind -n C-d' home/modules/terminal/tmux.nix && ! rg -q "'^D'" home/modules/terminal/zsh.nix`
  - Seam: home/modules/terminal/tmux.nix, home/modules/terminal/zsh.nix.
  - Behavior: Ctrl-D ends input in a shell or REPL; prefix-d opens the container popup..
  - Failures: Root binding steals EOF, zsh unbinds Ctrl-D, documented prefixes regress..
  - Ledger: tests/S75.md

- [ ] S77 [R15] [D87]: Every discovered host and user is covered by evaluated checks
  - Verify: `nix eval --json .#nixosConfigurations --apply 'c: builtins.length (builtins.attrNames c)' | grep -qx 2 && nix eval --json .#checks.x86_64-linux --apply 'c: builtins.hasAttr "ai-rendered" c && builtins.hasAttr "skills-rendered" c' | grep -qx true && nix flake check --no-build >/dev/null`
  - Seam: flake/default.nix, tests/default.nix, tests/layout.nix, tests/home.nix.
  - Behavior: Adding a host or user adds corresponding checks; no inline derivation shadows tests/..
  - Failures: Unchecked discovered output, inline check collision, untracked test silently dropped..
  - Ledger: tests/S77.md

- [ ] S87 [R10] [D97]: Every declared theme template has a matching asset and a checked consumer
  - Verify: `nix build .#checks.x86_64-linux.home --no-link >/dev/null && rg -q 'starship-palette.toml' tests/home.nix`
  - Seam: tests/home.nix, home/modules/programs/wallust.nix, assets/wallust-templates.
  - Behavior: Removing or renaming a declared template fails a check..
  - Failures: Hand-maintained asset list omits a template, stale theme target..
  - Ledger: tests/S87.md

- [ ] S96 [R10] [D106]: Editor checks assert evaluated behavior rather than file presence
  - Verify: `rg -q 'programs.nvf.settings' tests/home.nix && rg -q 'maparg|list_formatters|formatters_by_ft' tests/home.nix`
  - Seam: tests/home.nix.
  - Behavior: A regression in formatter maps or keymap binding fails a check..
  - Failures: String-only checks pass while editor behavior is broken..
  - Ledger: tests/S96.md

- [ ] S103 [R39] [D113]: Remote mount browsing is tuned without changing mount mode
  - Verify: `nix eval --json .#homeConfigurations.hollowheap.config.systemd.user.services.rclone-mount-gdrive.Service.ExecStart | jq -r '.[0]' | rg -q 'dir-cache-time 24h --vfs-cache-poll-interval 5m --vfs-fast-fingerprint'`
  - Seam: home/modules/services/rclone.nix.
  - Behavior: Directory listings stay fast while the remote remains mounted..
  - Failures: Switching to sync loses live mount, cache tuning removed..
  - Ledger: tests/S103.md

### AI and Editor

#### Framework & Library Choices

- [x] S47 [R20] [D51]: Neovim domain modules co-locate plugins, configuration, whichKey, and keymaps
  - Verify: test -f home/modules/programs/nvim/quickfix.nix && test -f home/modules/programs/nvim/preview.nix && test -f home/modules/programs/nvim/editing.nix && nix eval --raw .#homeConfigurations.hollowheap.config.programs.neovim.finalPackage.name >/dev/null
  - Seam: Neovim domain modularization.
  - Behavior: `quickfix.nix`, `preview.nix`, and `editing.nix` configure domain plugins and bindings directly; `core.nix` and `keymaps.nix` delegate domain logic without breaking existing editor keymaps.
  - Failures: orphan keymaps, broken lazy plugin definitions, module collisions.
  - Ledger: tests/S47.md

- [x] S48 [R19] [D53]: Universal harness rules with eager/lazy skill partitioning
  - Verify: nix build .#checks.x86_64-linux.home && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Seam: `home/modules/ai/rules.nix` and `home/modules/ai/agents.nix`.
  - Behavior: `rules.nix` encodes runner declaration, exact verify, gate integrity, experiment timebox, and subagent concurrency clamps; `agents.nix` keeps primary agents lean by pruning domain UI skills to workers and review auditors.
  - Failures: syntax errors in rules, broken capability filters, missing skills in worker.
  - Ledger: tests/S48.md

- [x] S49 [R19] [D54]: Frontend guidance is absorbed into the review UI lens
  - Verify: test -f assets/skills/review/references/ui.md
  - Seam: `assets/skills/review/references/ui.md`.
  - Behavior: UI authoring, accessibility, layout density, and token checks live in one review reference.
  - Failures: missing reference file or broken review routing.
  - Ledger: tests/S49.md

- [x] S50 [R19] [D55]: Backend guidance is absorbed into the review backend lens
  - Verify: test -f assets/skills/review/references/backend.md && test -f assets/skills/modular-design/SKILL.md
  - Seam: `assets/skills/review/references/backend.md` and `assets/skills/modular-design/SKILL.md`.
  - Behavior: Transport-boundary validation, thin handlers, pure services, error mapping, timeouts, and pool shutdown live in the review backend lens; `modular-design` still owns architecture seams.
  - Failures: missing reference file, broken review routing, or missing modular-design skill.
  - Ledger: tests/S50.md

- [x] S51 [R19] [D56]: Harness model routing and reasoning effort alignment
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.codex.settings && nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".kiro/agents/architect.json"'.text
  - Seam: `home/modules/programs/codex.nix`, `home/modules/programs/kiro-cli.nix`, `home/modules/ai/options.nix`.
  - Behavior: Codex settings and agents declare `model = "gpt-6-luna"` with `model_reasoning_effort = "xhigh"`; Kiro agents declare `claude-sonnet-5.5` at effort `low` for high tier (`architect`) and `claude-haiku-5.5` at effort `xhigh` for medium/low tiers; global `ai.tiers` default centralizes on `opencode-go`.
  - Failures: missing TOML keys, invalid JSON effort strings, broken eval.
  - Ledger: tests/S51.md

- [x] S52 [R19] [D80]: Declarative dynamic API key delivery for AI harnesses
  - Verify: env -u OPENCODE_API_KEY pi auth check --provider opencode-go && zsh -c 'source ~/.config/zsh/.zshrc && echo $OPENCODE_API_KEY'
  - Seam: `home/modules/terminal/zsh.nix`, `home/modules/programs/opencode.nix`, `home/modules/programs/pi-coding-agent.nix`, `home/modules/ai/hooks.nix`.
  - Behavior: OpenCode, Pi, and Crush resolve `OPENCODE_API_KEY` and `OPENCODE_GO_API_KEY` dynamically via `rbw`; `pi` natively evaluates `!rbw get --folder dev/keys opencode` from `~/.pi/agent/auth.json`; Zsh injects keys on startup and preexec before `opencode*`, `pi*`, `crush*`, `kiro*`, or `codex*`.
  - Failures: missing key in harness runtime, hardcoded secrets in dotfiles, hung repomap in bare `$HOME`.
  - Ledger: tests/S52.md

- [x] S62 [R28] [D66]: Every harness renders a non-empty agent body and one tier-consistent model and effort
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Seam: `home/lib/ai-render.nix`, `home/modules/ai/options.nix`, `home/modules/programs/*.nix`.
  - Behavior: each harness renders the shared agent body; changing an `ai.tiers` entry changes every renderer; no harness-local model table overrides a tier except `models.<harness>`.
  - Failures: empty agent body, prompt drift, hardcoded model or effort, missing adapter branch.
  - Ledger: tests/S62.md

- [ ] S68 [R28] [D83]: Codex evaluates enabled with a prebuilt package and no repeated native compilation
  - Verify: `nix eval .#homeConfigurations.hollowheap.config.programs.codex.enable | grep -qx true && ! rg -q 'AWS_LC_SYS_USE_SYSTEM' home/modules/programs/codex.nix && nix build .#homeConfigurations.hollowheap.activationPackage --no-link`
  - Seam: `home/modules/programs/codex.nix` and the Codex package derivation.
  - Behavior: Codex is enabled and its agent files, hooks, and settings render from a cached or upstream binary.
  - Failures: disabled adapter, vendored native build during activation, absent agent or hook files.
  - Ledger: tests/S68.md

- [ ] S69 [R28] [D84]: Kiro renders shared agent capabilities without subagent capability stripping
  - Verify: `! rg -q 'subagentOnly' home/modules/programs/kiro-cli.nix && nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".kiro/agents/worker.json"'.text | jq -e '.tools | index("web")'`
  - Seam: `home/modules/programs/kiro-cli.nix` and `ai.agents.<name>.capabilities`.
  - Behavior: Kiro emits the same declared tools and skills for primary and subagent roles; no harness-local pruning changes agent capability.
  - Failures: subagent-only gate, stripped `web` or write tools, capability drift from shared schema.
  - Ledger: tests/S69.md

- [x] S70 [R28] [D85]: Adapter-local model and effort replace shared routing abstractions
  - Verify: `! rg -q 'modelFor|effortFor|ai\.tiers|harness-routing' home/modules home/lib --glob '*.nix' && nix build .#homeConfigurations.hollowheap.activationPackage --no-link`
  - Seam: `home/modules/ai/options.nix`, `home/lib/ai-render.nix`, and every `home/modules/programs/*` adapter.
  - Behavior: each adapter sets its own model and effort; shared code contributes no model or tier table.
  - Failures: surviving shared helper, missing adapter-local model, eval error from removed routing option.
  - Ledger: tests/S70.md
- [ ] S89 [R52] [D99]: Markdown saves do not run a formatter outside the unified toolchain
  - Verify: `nix eval --json .#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.formatter.conform-nvim.setupOpts.formatters_by_ft | jq -e 'has("markdown") | not'`
  - Seam: home/modules/core/toolchain.nix, home/modules/programs/nvim/lsp.nix.
  - Behavior: Prose and bullets are preserved on save while other filetypes keep their formatters..
  - Failures: deno fmt reflows Markdown, unified no-formatter contract inert..
  - Ledger: tests/S89.md

- [ ] S90 [R52] [D100]: Neovim no longer advertises or restores sessions
  - Verify: `! rg -q 'Restore Session|section = "session"' home/modules/programs/nvim/snacks.nix && ! rg -q 'mini.sessions' home/modules/programs/nvim/mini.nix`
  - Seam: home/modules/programs/nvim/snacks.nix, home/modules/programs/nvim/mini.nix.
  - Behavior: Dashboard and keymaps contain no session-restore entry..
  - Failures: Dead restore UI, autoread surprise on launch..
  - Ledger: tests/S90.md

- [ ] S91 [R52] [D101]: Agent keymaps remain present despite headless maparg limitations
  - Verify: `rg -q '"<leader>ar"' home/modules/programs/nvim/keymaps.nix && rg -q 'AvanteAsk|AvanteToggle|AvanteFocus' home/modules/programs/nvim/keymaps.nix`
  - Seam: home/modules/programs/nvim/keymaps.nix.
  - Behavior: The documented leader-a commands remain bound in a real session..
  - Failures: Headless probe deletes working bindings or which-key descriptions drift..
  - Ledger: tests/S91.md

- [ ] S92 [R52] [D102]: ACP providers use Nix-resolved paths instead of machine-local checkout literals
  - Verify: `! rg -q '/home/hollowheap/repos' home/modules/programs/nvim/completion.nix && rg -q 'acp_providers' home/modules/programs/nvim/completion.nix`
  - Seam: home/modules/programs/nvim/completion.nix, pkgs/default.nix.
  - Behavior: Provider paths resolve from Nix on every host..
  - Failures: Hardcoded home path, provider fails after checkout moves..
  - Ledger: tests/S92.md

- [ ] S93 [R52] [D103]: Shell scripts format with the unified formatter
  - Verify: `nix eval --json .#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.formatter.conform-nvim.setupOpts.formatters_by_ft | jq -e '.bash == ["shfmt"] and .zsh == ["shfmt"]'`
  - Seam: home/modules/core/toolchain.nix, home/modules/programs/nvim/lsp.nix.
  - Behavior: Format-on-save works for bash and zsh buffers..
  - Failures: Only sh key registered, shfmt installed but unused..
  - Ledger: tests/S93.md

- [ ] S99 [R52] [D109]: Every supported ACP provider is registered in the editor
  - Verify: `rg -q 'pi =' home/modules/programs/nvim/completion.nix && rg -q 'claude' home/modules/programs/nvim/completion.nix && rg -q 'agy' home/modules/programs/nvim/completion.nix && rg -q 'opencode' home/modules/programs/nvim/completion.nix`
  - Seam: home/modules/programs/nvim/completion.nix, docs/avante provider list.
  - Behavior: The named harnesses appear as selectable ACP providers..
  - Failures: Only Pi registered, provider list incomplete..
  - Ledger: tests/S99.md

#### Data & Contracts

- [x] S63 [R29] [D82]: MCP-capable agents see the same enabled stdio servers in every supporting harness
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.mcp.servers
  - Seam: `home/modules/ai/options.nix`, `home/modules/programs/{opencode,codex,crush,github-copilot-cli}.nix`.
  - Behavior: one server definition controls command, args, environment, and enablement in every supporting harness; agents without MCP capability receive no server access.
  - Failures: server present in only one harness, divergent arguments, capability bypass.
  - Ledger: tests/S63.md

- [x] S64 [R30] [D68]: One hook definition renders consistently and malformed pre-tool input blocks the tool
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.hooks
  - Seam: `home/modules/ai/hooks.nix`, `home/modules/ai/options.nix`, `home/modules/programs/*.nix`.
  - Behavior: event, command, args, matcher, timeout, enablement, and harness filters produce equivalent native adapters; unsupported event/harness pairs fail evaluation; malformed pre-tool payloads exit nonzero.
  - Failures: ignored command, divergent matcher, fail-open pre-tool hook.
  - Ledger: tests/S64.md

- [x] S67 [R29] [D82]: MCP servers render from one shared registry into every capable harness, including Pi
  - Verify: `nix eval --json .#homeConfigurations.hollowheap.config.programs.mcp.servers | jq -e '.refero.exposure == "codemode"' && ! rg -q 'mcpServers' home/modules/programs/pi-coding-agent.nix`
  - Seam: `home/modules/ai/options.nix`, `programs.mcp.servers`, and every MCP-capable harness adapter.
  - Behavior: one server definition controls URL, command, environment, enablement, and codemode exposure; Pi consumes the registry instead of a private file.
  - Failures: private Pi registry, server missing from a capable adapter, direct MCP tool exposure, capability bypass.
  - Ledger: tests/S67.md
- [ ] S76 [R27] [D76]: Agent capabilities and artifact paths are enforced consistently across harnesses
  - Verify: `nix eval --raw .#homeConfigurations.hollowheap --apply 'h: h.config.ai.render.agentBodyFor h.config.ai.agents.worker' | rg -q 'Task executor' && ! rg -q 'subagent-io' home/modules/ai/agents.nix && rg -q '\.artifacts/\*\.md' home/modules/programs/kiro-cli.nix`
  - Seam: home/modules/ai/options.nix, home/modules/ai/agents.nix, home/modules/programs/kiro-cli.nix, lib/ai-skills.nix.
  - Behavior: Write-capable agents avoid read-only mandates; canonical artifact globs and parsed skills hold..
  - Failures: Contradictory discipline, lowercase artifact paths, malformed skill YAML, fail-open hooks..
  - Ledger: tests/S76.md

#### Operations & Security

- [x] S65 [R27] [D65]: Declared capabilities produce enforceable permissions and no invalid `write` key
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Seam: `home/modules/programs/opencode.nix`, `home/modules/ai/options.nix`, `home/modules/programs/*.nix`.
  - Behavior: deny-all precedes specific allows; architect can edit artifacts and delegate to scout; task allows derive from `availableAgents`; non-OpenCode harnesses map capabilities to native tool lists.
  - Failures: deny-last ordering, `write` permission key, denied delegation, capability tool mismatch.
  - Ledger: tests/S65.md

- [x] S66 [R30] [D81]: Hook contracts drop external hooks when a harness provides an equivalent builtin
  - Verify: `nix build .#checks.x86_64-linux.home --no-link && nix eval --json .#homeConfigurations.hollowheap.config.ai.hooks --apply 'h: builtins.hasAttr "pre-tool" h' | grep -qx true`
  - Seam: `home/modules/ai/hooks.nix`, `home/lib/ai-render.nix`, and each harness hook adapter.
  - Behavior: the shared contract declares hook intent once; an adapter omits an external command when its harness performs the same policy natively, while remaining hooks keep one command, matcher, and timeout shape.
  - Failures: duplicate external hook beside a builtin, dropped hook with no builtin substitute, per-harness hook reimplementation, fail-open pre-tool execution.
  - Ledger: tests/S66.md

- [x] S71 [R10] [D86]: Repomap hook, generator, and artifacts are removed
  - Verify: `! rg -q 'repomap' home/modules/ai/hooks.nix && test ! -f pkgs/repomap.nix && test ! -e .artifacts/repomap.md && ! rg -q 'repomap' .artifacts/ARCHITECTURE.md`
  - Seam: `home/modules/ai/hooks.nix`, `pkgs/repomap.nix`, `.artifacts/REPOMAP.md`, and Kiro resource declarations.
  - Behavior: no hook generates or consumes a repomap; no tracked or generated repomap remains in this repository.
  - Failures: surviving lowercase map, hook still writing a map, Kiro resource pointing at a removed file, documentation still claiming a repomap.
  - Ledger: tests/S71.md

### Desktop and Theme

#### Framework & Library Choices

- [x] S53 [R08] [D58]: Declarative XDG user directories and Wallust template unification
  - Verify: test -f ~/.config/user-dirs.dirs && grep -q 'XDG_TEMPLATES_DIR' ~/.config/user-dirs.dirs && test -d ~/.local/share/templates
  - Seam: `home/modules/environment/session.nix`, `home/modules/programs/wallust.nix`, `home/modules/programs/noctalia.nix`.
  - Behavior: `xdg.userDirs` declares standard user folders and redirects template/desktop/public to `~/.local/share/`; Wallust templates deploy into `${config.xdg.userDirs.templates}` and mirror to `~/.config/wallust/templates`; Noctalia invokes Wallust with `--templates-dir`.
  - Failures: missing user-dirs.dirs, broken wallust template resolution, cluttered `$HOME`.
  - Ledger: tests/S53.md

- [x] S56 [R23] [D72]: OMP module provides `programs.omp.enable`, generates `~/.omp/agent/` config, skills, agents, and hooks, and builds activation package
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Seam: `flake.nix`, `flake/default.nix`, `home/modules/programs/omp.nix`, `home/modules/ai/hooks.nix`.
  - Behavior: `programs.omp.enable = true` installs `omp` package, registers `inputs.omp.homeManagerModules.default`, deploys skills into `~/.omp/agent/skills/`, writes agent markdown files into `~/.omp/agent/agents/`, renders disciplines into `SYSTEM.md`, and connects pre-tool and session-start hooks.
  - Failures: flake input resolution errors, broken HM module imports, missing package outputs, invalid activation package.
  - Ledger: tests/S56.md

- [x] S57 [R24] [D62]: Pi built-in extension exclusions
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.pi-coding-agent.settings.extensions && nix build .#checks.x86_64-linux.home
  - Seam: `home/modules/programs/pi-coding-agent.nix`, `tests/home.nix`.
  - Behavior: `programs.pi-coding-agent.settings.extensions` specifies `["-builtin:tool-search" "-builtin:mcp" "-builtin:llama.cpp"]`; Home Manager renders this into `~/.pi/agent/settings.json`; tests in `tests/home.nix` assert grep matches.
  - Failures: invalid JSON syntax, missing extension override syntax, broken eval.
  - Ledger: tests/S57.md

- [x] S58 [R25] [D63]: Noctalia builtin Hyprland template and wallpaper hook
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.noctalia.settings.theme.templates.builtin_ids | grep -q '"hyprland"' && grep -q wallust "$(nix eval --raw .#homeConfigurations.hollowheap.config.programs.noctalia.settings.hooks.wallpaper_changed)"
  - Seam: `home/modules/programs/noctalia.nix`, `home/modules/programs/hyprland/hyprland.nix`, `pkgs/mactahoe-icon-accent.py`.
  - Behavior: Noctalia's builtin `hyprland` template owns `~/.config/hypr/noctalia.lua`; Hyprland's `_var` resolver calls `apply_theme` and maps `m.colors`; the wallpaper hook still runs Wallust for remaining consumers and updates GTK/icon accents.
  - Failures: builtin template omitted, Hyprland color resolver missing, icon theme sync failure.
  - Ledger: tests/S58.md

- [x] S59 [R26] [D64]: Neovim in-buffer diagrams and image support
  - Verify: nix eval --raw '.#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.lazy.plugins."diagram.nvim".setupModule' | grep -q "diagram" && nix build .#checks.x86_64-linux.home
  - Seam: `home/modules/programs/nvim/diagrams.nix`, `home/modules/programs/nvim.nix`, `flake/default.nix`, `tests/home.nix`.
  - Behavior: `home/modules/programs/nvim/diagrams.nix` exports `image.nvim` (eager start plugin with Kitty protocol and `magick_cli`) and `diagram.nvim` (lazy plugin with markdown/neorg integrations and dark mermaid/plantuml/d2 renderers); registers `<leader>m` bindings for render, clear, and hover; adds CLI tools (`imagemagick`, `mermaid-cli`, `plantuml`, `d2`, `graphviz`) to `programs.nvf.settings.vim.extraPackages`.
  - Failures: unfree license evaluation errors, missing CLI executables, start/opt plugin collision warnings.
  - Ledger: tests/S59.md
- [ ] S78 [R04] [D122]: HDR is available on the hardware that supports it and absent elsewhere
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.desktop.hdr | jq -e '. == true' && nix eval --json .#nixosConfigurations.acervus.config.desktop.hdr | jq -e '. == false' && nix eval --json .#homeConfigurations.hollowheap.config.desktop.hdr | jq -e '. == false'`
  - Seam: hardware/hdr.nix, hosts/lacuna/hardware.nix, home/hollowheap.nix, home/modules/programs/hyprland/hyprland.nix.
  - Behavior: Lacuna compositor enables HDR; acervus and headless contexts stay SDR..
  - Failures: Orphan trait setter, HDR on unsupported hardware, cross-layer disagreement..
  - Ledger: tests/S78.md

- [ ] S83 [R39] [D93]: Power saving lowers the actual configured refresh rate
  - Verify: `nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".config/hypr/scripts/power-mode.sh"'.text | rg -q '@60' && ! rg -q 'replaceStrings' home/modules/services/power-mode.nix`
  - Seam: home/modules/services/power-mode.nix, modules/options/desktop.nix.
  - Behavior: A 120 Hz monitor drops to 60 Hz in power-saver without literal substitution..
  - Failures: Non-120 modes stay fast, per-monitor scale discarded..
  - Ledger: tests/S83.md

- [ ] S84 [R07] [D94]: Login screen uses the installed shared font families
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.fonts.packages | jq -e 'length > 0' && nix eval --raw .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.appearance.font_family | grep -q .`
  - Seam: roles/desktop/system/default.nix, modules/options/desktop.nix.
  - Behavior: Sans, serif, and monospace packages are installed for the greeter..
  - Failures: Generic fallback font, HM-only font installation..
  - Ledger: tests/S84.md

- [ ] S98 [R50] [D108]: Dynamic colorschemes remain the only palette authority
  - Verify: `! test -e home/modules/styles/palette.nix && rg -q 'wallust' home/modules/programs/wallust.nix && rg -q 'theme' home/modules/programs/noctalia.nix`
  - Seam: home/modules/programs/wallust.nix, home/modules/programs/noctalia.nix, home/modules/styles.
  - Behavior: New colors come from wallpaper-derived schemes and no static ramp is planned..
  - Failures: Static palette module resurrected, two color authorities drift..
  - Ledger: tests/S98.md

#### Data & Contracts
- [ ] S79 [R08] [D89]: Laptop geometry is supplied by host data, not shared defaults
  - Verify: `nix eval --json .#nixosConfigurations.acervus.config.desktop.primaryOutput | jq -e '. == null' && nix eval --raw .#nixosConfigurations.lacuna.config.desktop.primaryOutput | grep -qx eDP-1`
  - Seam: modules/options/desktop.nix, hosts/lacuna/default.nix, home/hosts/lacuna.nix.
  - Behavior: Headless hosts carry no phantom panel layout; compositor values come from lacuna data..
  - Failures: Laptop defaults leak to acervus, HM overlay missing, monitor list empty..
  - Ledger: tests/S79.md

- [ ] S88 [R08] [D98]: Wacom and Yoga switch names are host-scoped options
  - Verify: `nix eval --raw .#homeConfigurations.hollowheap.config.desktop.touchscreen.switchDevice | grep -q . && ! rg -q 'wacom-hid-53b7' home/modules/environment/touch.nix home/modules/programs/hyprland/keybinds.nix`
  - Seam: home/modules/environment/touch.nix, home/modules/programs/hyprland/keybinds.nix, home/hosts/lacuna.nix.
  - Behavior: Non-Yoga hosts do not receive vendor-specific device bindings..
  - Failures: Vendor literals in shared modules, missing host override..
  - Ledger: tests/S88.md

- [ ] S95 [R50] [D105]: Syntax roles keep distinguishable generated colors
  - Verify: `rg -q -F "base08 = '{{color9}}'" assets/wallust-templates/nvim-colors.lua && rg -q -F "base09 = '{{color11}}'" assets/wallust-templates/nvim-colors.lua && rg -q -F "base0A = '{{color3}}'" assets/wallust-templates/nvim-colors.lua && rg -q -F "base0F = '{{color5}}'" assets/wallust-templates/nvim-colors.lua`
  - Seam: assets/wallust-templates/nvim-colors.lua, home/modules/programs/nvim/ui.nix.
  - Behavior: Errors, constants, keywords, and deprecated tags remain visually separable..
  - Failures: Four roles collapse into two bright slots..
  - Ledger: tests/S95.md

#### Module Seams

- [x] S54 [R21] [D59]: Vertical domain slices for server role daemons
  - Verify: test -f roles/server/system/caddy.nix && test -f roles/server/system/headscale.nix && test -f roles/server/system/vaultwarden.nix && test -f roles/server/system/ddclient.nix && nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run
  - Seam: `roles/server/system/{default,caddy,headscale,vaultwarden,ddclient,domains}.nix`.
  - Behavior: `caddy.nix` provides base reverse proxy engine, plugin wrapper, and DNS-01 certs; `headscale.nix`, `vaultwarden.nix`, and `ddclient.nix` configure respective services, secrets, and virtualHost reverse proxy mappings; `default.nix` aggregates imports; `tests/services.nix` passes.
  - Failures: conflicting vhost names, missing firewall ports, broken sops secret bindings, circular dependencies.
  - Ledger: tests/S54.md

- [x] S55 [R22] [D60]: Decoupled home module taxonomy across terminal, cli, and programs
  - Verify: test -d home/modules/terminal && test -d home/modules/cli && test -d home/modules/programs && nix build .#checks.x86_64-linux.home && nix build .#checks.x86_64-linux.layout
  - Seam: `home/modules/{terminal,cli,programs}/`, `tests/home.nix`, `AGENTS.md`.
  - Behavior: Interactive shell and multiplexers move to `terminal/` (`zsh`, `starship`, `tmux`, `zoxide`, `direnv`); headless tools move to `cli/` (`git`, `lazygit`, `bat`, `btop`, `yazi`, `fastfetch`, `tealdeer`, `gpg`, `ssh`, `utilities`); GUI apps, editors, and AI harnesses remain in `programs/`; `import-tree` discovers all modules without configuration breakage.
  - Failures: broken file paths in `tests/home.nix`, missing dependencies, syntax regressions.
  - Ledger: tests/S55.md
- [ ] S73 [R08] [D73]: Host-specific display, Wacom, and Yoga values stay outside shared desktop options
  - Verify: `test -d home/hosts && nix eval --raw .#homeConfigurations.hollowheap.config.desktop.touchscreen.switchDevice >/dev/null && nix eval --json .#homeConfigurations.hollowheap.config.desktop.monitors | jq -e 'length > 0'`
  - Seam: modules/options/desktop.nix, home/hollowheap.nix, home/hosts/lacuna.nix, hosts/lacuna/default.nix.
  - Behavior: Shared desktop defaults stay neutral while lacuna supplies concrete hardware values..
  - Failures: Laptop literals in shared defaults, absent host overlay, compositor drift..
  - Ledger: tests/S73.md

- [ ] S80 [R07] [D90]: Login and desktop sessions consume the same output, layout, input, and font policy
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.output | jq -e 'has("name")' && nix eval --json .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.keyboard | jq -e 'has("variant") and has("options")' && nix eval --raw .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.appearance.font_family | grep -q .`
  - Seam: roles/desktop/system/default.nix, modules/options/desktop.nix, home/modules/programs/hyprland/hyprland.nix.
  - Behavior: Changing shared desktop data changes both login and compositor surfaces..
  - Failures: Greeter pins eDP-1, drops XKB variant/options, or omits font family..
  - Ledger: tests/S80.md

- [ ] S81 [R04] [D91]: Desktop shell touch and compositor touch are separate host-scoped policies
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.desktop.touch | grep -qx true && nix eval --json .#homeConfigurations.hollowheap.config.desktop.touch | grep -qx true && rg -q 'config.desktop.touch' home/modules/programs/hyprland/hyprland.nix`
  - Seam: hardware/touch.nix, home/hollowheap.nix, home/hosts/lacuna.nix, home/modules/environment/touch.nix, home/modules/programs/hyprland/hyprland.nix.
  - Behavior: Each layer owns its touch integration; no orphan NixOS setter or unconditional HM flag..
  - Failures: Duplicate boolean, version throw on non-touch host, shell/compositor disagreement..
  - Ledger: tests/S81.md

- [ ] S85 [R07] [D95]: Compositor geometry no longer exposes an unused bar-height option
  - Verify: `! rg -q 'barHeight' home/modules/environment/compositor.nix home/modules/programs/hyprland home/modules/programs/noctalia.nix`
  - Seam: home/modules/environment/compositor.nix, home/modules/programs/noctalia.nix.
  - Behavior: Setting or removing bar height has no dead option surface..
  - Failures: Dead option advertised, panel geometry split across modules..
  - Ledger: tests/S85.md

- [ ] S86 [R07] [D96]: Portal ownership stays system-level with the Hyprland portal selected
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.xdg.portal.enable | jq -e '. == true' && nix eval --json .#nixosConfigurations.lacuna.config.xdg.portal.extraPortals | jq -e 'length > 0'`
  - Seam: roles/desktop/system/default.nix, home/modules/environment/rules.nix.
  - Behavior: Screen-share and file-picker rules match the installed portal..
  - Failures: Portal config in user scope, portal app id mismatch..
  - Ledger: tests/S86.md

- [ ] S94 [R50] [D104]: Compositor start re-applies the persisted wallpaper theme
  - Verify: `rg -q 'settings.toml' home/modules/programs/noctalia.nix && rg -q 'wallpaper.last' home/modules/programs/noctalia.nix`
  - Seam: home/modules/programs/noctalia.nix.
  - Behavior: Restarting the shell restores GTK, icon, and Wallust state without a wallpaper change..
  - Failures: Started hook gated on a change-only environment variable..
  - Ledger: tests/S94.md

- [ ] S97 [R10] [D107]: Dead wallust pill helper is removed
  - Verify: `! rg -q 'pill_load_wallust' home/modules/styles/pills.nix`
  - Seam: home/modules/styles/pills.nix.
  - Behavior: No uncalled helper claims EOF-safe palette parsing..
  - Failures: Dead 108-line bash helper persists as misleading contract..
  - Ledger: tests/S97.md

### Skills and Workflow

#### Module Seams

- [x] S60 [R18] [D72]: On-demand retro skill evaluates active session transcript
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.retro.description | grep -q "retrospective" && test -f home/modules/ai/skills.nix
  - Seam: `home/modules/ai/skills.nix`.
  - Behavior: `ai.skills.retro` provides single-session retrospective auditing tool efficiency, failure counts, rule compliance, and winning patterns directly from the active transcript into `.artifacts/RETRO.md`.
  - Failures: missing skill definition, invalid markdown schema.
  - Ledger: tests/S60.md

- [x] S61 [R19] [D72]: Corpus-audit skill ingests compacted transcripts across sessions
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.corpus-audit.description | grep -q "corpus-audit" && test -f home/modules/ai/skills.nix
  - Seam: `home/modules/ai/skills.nix`.
  - Behavior: `ai.skills.corpus-audit` provides cross-session auditing for systemic knowledge amnesia, thinking loops, and prompt waste to feed into `author-harness`.
  - Failures: missing skill definition, invalid markdown schema.
  - Ledger: tests/S61.md
