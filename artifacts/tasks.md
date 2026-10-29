# Tasks

Active tasks, completed history, and verification commands. Requirements live in `artifacts/requirements.md`; decisions in `artifacts/decisions.md`; invariants in `artifacts/specs.md`.

## Completed — Restored historical range

- [x] T48 [S35] (blocked-by: none): Extract shared module discovery to `lib/default.nix`
  - Verify: grep -q "mkModuleLoader" modules/default.nix
  - Files: restored historical change.
  - Notes: current equivalent is part of the S35 contract.
  - Risk: stale option or path.

- [x] T49 [S36] (blocked-by: none): Port recursive package discovery to `pkgs/default.nix`
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.double-minegrub-menu.name | grep -q double-minegrub-menu
  - Files: restored historical change.
  - Notes: current equivalent is part of the S36 contract.
  - Risk: stale option or path.

- [x] T50 [S01] (blocked-by: none): Modularize flake outputs into `flake/default.nix`
  - Verify: test -f flake/default.nix
  - Files: restored historical change.
  - Notes: current equivalent is part of the S01 contract.
  - Risk: stale option or path.

- [x] T51 [S01] (blocked-by: none): Standardize repo skills under `skills/`
  - Verify: test -d skills/nix-flake-eval
  - Files: restored historical change.
  - Notes: current equivalent is part of the S01 contract.
  - Risk: stale option or path.

- [x] T52 [S37] (blocked-by: none): Add the maintenance devShell
  - Verify: nix eval .#devShells.x86_64-linux.default.name >/dev/null
  - Files: restored historical change.
  - Notes: current equivalent is part of the S37 contract.
  - Risk: stale option or path.

- [x] T53 [S17] (blocked-by: none): Deploy rootless Podman
  - Verify: nix eval .#nixosConfigurations.lacuna.config.virtualisation.podman.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S17 contract.
  - Risk: stale option or path.

- [x] T54 [S17] (blocked-by: none): Expose the Docker socket
  - Verify: nix eval .#nixosConfigurations.lacuna.config.virtualisation.podman.dockerSocket.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S17 contract.
  - Risk: stale option or path.

- [x] T55 [S17] (blocked-by: none): Enable container DNS resolution
  - Verify: nix eval .#nixosConfigurations.lacuna.config.virtualisation.podman.defaultNetwork.settings.dns_enabled | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S17 contract.
  - Risk: stale option or path.

- [x] T56 [S17] (blocked-by: none): Grant the podman group through the admin seam
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.extraGroups | grep -q podman
  - Files: restored historical change.
  - Notes: current equivalent is part of the S17 contract.
  - Risk: stale option or path.

- [x] T57 [S06] (blocked-by: none): Silence console boot noise
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.consoleLogLevel | grep -qx 0
  - Files: restored historical change.
  - Notes: current equivalent is part of the S06 contract.
  - Risk: stale option or path.

- [x] T58 [S11] (blocked-by: none): Silence UWSM startup output
  - Verify: nix eval .#nixosConfigurations.lacuna.config.environment.sessionVariables.UWSM_SILENT_START | grep -qx 2
  - Files: restored historical change.
  - Notes: current equivalent is part of the S11 contract.
  - Risk: stale option or path.

- [x] T59 [S05] (blocked-by: none): Decouple the Nvidia driver stack
  - Verify: nix eval .#nixosConfigurations.acervus.config.hardware.nvidia.modesetting.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S05 contract.
  - Risk: stale option or path.

- [x] T60 [S26] (blocked-by: none): Enable Intel microcode
  - Verify: nix eval .#nixosConfigurations.lacuna.config.hardware.cpu.intel.updateMicrocode | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S26 contract.
  - Risk: stale option or path.

- [x] T61 [S07] (blocked-by: none): Declare the Disko GPT/LUKS/BTRFS layout
  - Verify: nix eval .#nixosConfigurations.lacuna.config.disko.devices.disk.main.type | grep -qx disk
  - Files: restored historical change.
  - Notes: current equivalent is part of the S07 contract.
  - Risk: stale option or path.

- [x] T62 [S27] (blocked-by: none): Enable TPM2 systemd initrd unlock
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.tpm2.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S27 contract.
  - Risk: stale option or path.

- [x] T63 [S28] (blocked-by: none): Add Secure Boot signing hooks
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.extraInstallCommands | grep -q sbctl
  - Files: restored historical change.
  - Notes: current equivalent is part of the S28 contract.
  - Risk: stale option or path.

- [x] T64 [S30] (blocked-by: none): Enable PipeWire audio
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.pipewire.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S30 contract.
  - Risk: stale option or path.

- [x] T65 [S31] (blocked-by: none): Enable DNS-over-TLS
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.resolved.extraConfig | grep -q security.cloudflare-dns.com
  - Files: restored historical change.
  - Notes: current equivalent is part of the S31 contract.
  - Risk: stale option or path.

- [x] T66 [S32] (blocked-by: none): Use NetworkManager with iwd
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.networking.networkmanager.wifi.backend | grep -qx iwd
  - Files: restored historical change.
  - Notes: current equivalent is part of the S32 contract.
  - Risk: stale option or path.

- [x] T67 [S10] (blocked-by: none): Decrypt host secrets with the SSH age key
  - Verify: nix eval .#nixosConfigurations.lacuna.config.sops.defaultSopsFormat | grep -qx yaml
  - Files: restored historical change.
  - Notes: current equivalent is part of the S10 contract.
  - Risk: stale option or path.

- [x] T68 [S33] (blocked-by: none): Enable removable-media daemons
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.udisks2.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S33 contract.
  - Risk: stale option or path.

- [x] T69 [S34] (blocked-by: none): Enable laptop power management
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.thermald.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S34 contract.
  - Risk: stale option or path.

- [x] T70 [S40] (blocked-by: none): Enable BTRFS autoScrub
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.btrfs.autoScrub.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S40 contract.
  - Risk: stale option or path.

- [x] T71 [S08] (blocked-by: none): Deploy Headscale and Caddy
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.headscale.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S08 contract.
  - Risk: stale option or path.

- [x] T72 [S08] (blocked-by: none): Deploy loopback Vaultwarden
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.vaultwarden.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S08 contract.
  - Risk: stale option or path.

- [x] T73 [S11] (blocked-by: none): Deploy Noctalia greeter
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S11 contract.
  - Risk: stale option or path.

- [x] T74 [S11] (blocked-by: none): Enable Hyprland with UWSM
  - Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S11 contract.
  - Risk: stale option or path.

- [x] T75 [S01] (blocked-by: none): Enable weekly Nix GC and optimisation
  - Verify: nix eval .#nixosConfigurations.lacuna.config.nix.settings.auto-optimise-store | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S01 contract.
  - Risk: stale option or path.

## Completed — Current implementation

- [x] T01 [S01] (blocked-by: none): Merge Home Manager into `home/` and expose NixOS and standalone outputs
  - Verify: nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath >/dev/null && nix eval .#nixosConfigurations.lacuna.config.system.build.toplevel.drvPath >/dev/null
  - Files: `flake.nix`, `flake/default.nix`, `home/`, `hosts/lacuna/default.nix`.
  - Notes: copied the current Home Manager visual modules from the sibling repository.
  - Risk: missing input, divergent option sets.

- [x] T02 [S03] (blocked-by: T01): Generate hosts from `hosts/<name>/default.nix` and compose profiles, roles, and traits
  - Verify: grep -q "profiles/laptop" hosts/lacuna/default.nix && grep -q "roles/server/system" hosts/lacuna/default.nix && test -f hosts/lacuna/hardware.nix
  - Files: `flake/default.nix`, `hosts/lacuna`, `hosts/acervus`.
  - Notes: host-local `hardware.nix` groups traits; `boot.nix` groups boot components.
  - Risk: double profile imports, hidden hardware in profiles.

- [x] T03 [S02] (blocked-by: T01): Keep NixOS on release-26.05 and standalone Home Manager on unstable
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.lib.version | grep -q "26\.05" && nix eval --raw .#homeConfigurations.hollowheap.pkgs.lib.version | grep -q "26\.11"
  - Files: `flake.nix`, `modules/system/nixpkgs.nix`, `flake/default.nix`.
  - Notes: standalone Home Manager evaluates with unstable pkgs; NixOS does not import the HM module.
  - Risk: unstable drivers leaking into NixOS.

- [x] T04 [S06] (blocked-by: T01): Split boot into kernel, GRUB, TPM, Secure Boot, Minegrub, and Plymouth modules
  - Verify: for f in grub tpm secure-boot minegrub kernel plymouth; do test -f boot/$f.nix; done && test ! -e modules/boot/boot.nix
  - Files: `boot/`, `hosts/lacuna/boot.nix`, `hosts/acervus/boot.nix`.
  - Notes: hosts import only the boot components they use.
  - Risk: missing GRUB or TPM module, duplicate boot settings.

- [x] T05 [S07] (blocked-by: T01): Keep the Disko LUKS/BTRFS layout in the lacuna host
  - Verify: test -f hosts/lacuna/disko.nix && nix eval .#nixosConfigurations.lacuna.config.disko.devices.disk.main.type | grep -qx disk
  - Files: `hosts/lacuna/disko.nix`.
  - Notes: acervus keeps a placeholder until installation.
  - Risk: unencrypted root, missing subvolumes.

- [x] T06 [S04] (blocked-by: T01): Gate touch and HDR through hardware flags in the standalone Home Manager output
  - Verify: grep -q "desktop.touch = true" hardware/touch.nix && grep -q "desktop.hdr = true" hardware/hdr.nix && grep -q "desktop.touch = true" home/hollowheap.nix && grep -Rq "config.desktop.touch" home/modules/gui
  - Files: `hardware/touch.nix`, `hardware/hdr.nix`, `home/modules/cli/desktop-options.nix`, `home/modules/gui/touch.nix`, `home/modules/gui/hdr.nix`, `flake/default.nix`.
  - Notes: standalone HM sets the flags directly; NixOS no longer imports Home Manager.
  - Risk: missing flag, compositor ignoring it.

- [x] T07 [S05] (blocked-by: T06): Keep lacuna Intel-only and import hybrid Intel + Nvidia on acervus
  - Verify: grep -q "hybrid-gpu" hosts/acervus/default.nix && ! grep -q "hybrid-gpu" hosts/lacuna/hardware.nix && nix eval .#nixosConfigurations.acervus.config.hardware.nvidia.prime.offload.enable | grep -qx true
  - Files: `hardware/nvidia.nix`, `hardware/hybrid-gpu.nix`, `hosts/acervus/default.nix`.
  - Notes: Nvidia unfree names live in the Nvidia trait.
  - Risk: driver/kernel mismatch, stale PRIME bus IDs.

- [x] T08 [S17] (blocked-by: T01): Add `users.adminExtraGroups` and let modules own their groups
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.extraGroups | grep -q '"podman"' && ! grep -q '"podman"' modules/system/users.nix
  - Files: `modules/options/users.nix`, `modules/system/users.nix`, `modules/virtualisation/podman.nix`, `hardware/wifi.nix`, `hardware/rgb.nix`, `boot/tpm.nix`, `hardware/graphics.nix`.
  - Notes: Podman, Wi-Fi, RGB, TPM, and graphics append groups.
  - Risk: stale groups on hosts that omit a module.

- [x] T09 [S16] (blocked-by: T03): Replace the hardcoded unfree list with a declarable `unfreePackages` option
  - Verify: nix eval .#nixosConfigurations.lacuna.config.unfreePackages --apply 'ps: builtins.elem "steam" ps' | grep -qx true && grep -q "config.unfreePackages" modules/system/nixpkgs.nix
  - Files: `modules/options/unfree.nix`, `modules/system/nixpkgs.nix`, `hardware/nvidia.nix`.
  - Notes: owning modules append their package names.
  - Risk: predicate not applied to the unstable set.

- [x] T10 [S08] (blocked-by: T01): Run Headscale, Vaultwarden, Caddy, and ddclient from the lacuna server role
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[true,true,true,true\]'
  - Files: `roles/server/system/default.nix`, `hosts/lacuna/default.nix`.
  - Notes: acervus does not import the server role yet.
  - Risk: duplicated services, acervus running the vault.

- [x] T11 [S09] (blocked-by: T10): Use Caddy internal TLS for loopback names and point tailscaled at its CA
  - Verify: grep -q "tls internal" roles/server/system/default.nix && grep -q "SSL_CERT_FILE" roles/server/system/default.nix
  - Files: `roles/server/system/default.nix`.
  - Notes: DNS-01 remains a future task.
  - Risk: untrusted CA, ACME retries.

- [x] T12 [S10] (blocked-by: T01): Rekey sops to lacuna's age key, keep admin PGP recovery, and install secrets via systemd
  - Verify: grep -q "&lacuna age1cum" .sops.yaml && grep -q "recipient: age1cum" secrets.yaml && nix eval .#nixosConfigurations.lacuna.config.sops.useSystemdActivation | grep -qx true
  - Files: `.sops.yaml`, `secrets.yaml`, `modules/security/sops.nix`.
  - Notes: `sops updatekeys --yes` completed; activation decrypts at boot.
  - Risk: wrong recipient, lost recovery key.

- [x] T13 [S19] (blocked-by: T12): Restore `vaultwarden_env` and generate an admin token
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services.vaultwarden.environmentFile | grep -q "/run/secrets/vaultwarden_env" && grep -q "vaultwarden_env:" secrets.yaml
  - Files: `roles/server/system/default.nix`, `secrets.yaml`.
  - Notes: token is generated and retrievable with `sops decrypt --extract`.
  - Risk: missing env file, token in git.

- [x] T14 [S15] (blocked-by: T01): Add the flake checks
  - Verify: nix flake check
  - Files: `flake/default.nix`.
  - Notes: checks profile, role, hardware, boot, Home Manager, and Termux paths.
  - Risk: stale path checks, missing files.

- [x] T15 [S14] (blocked-by: T01): Add the `fovea` nix-on-droid output
  - Verify: nix eval .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx "24.05" && test ! -d hosts/fovea
  - Files: `flake.nix`, `flake/default.nix`, `nix-on-droid.nix`.
  - Notes: output uses unstable aarch64 and stays outside host enumeration.
  - Risk: missing input, host directory collision.

- [x] T16 [S11] (blocked-by: T01): Keep the system session and wire Home Manager user configuration
  - Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Files: `roles/desktop/system/default.nix`, `flake/default.nix`, `home/modules/gui`.
  - Notes: system owns greeter, package, and portals.
  - Risk: double compositor, missing greeter.

- [x] T17 [S12] (blocked-by: T16): Split `home/modules/cli` and `home/modules/gui`
  - Verify: ! grep -R "home/modules/gui" home/modules/cli && grep -Rq "launchApp" home/modules/cli && grep -Rq "defaultApps" home/modules/cli
  - Files: `home/modules/cli`, `home/modules/gui`, `home/cli.nix`, `home/gui.nix`.
  - Notes: shared options live in the CLI tier.
  - Risk: GUI leakage into CLI, duplicate options.

- [x] T18 [S13] (blocked-by: T17): Render the neutral shortcut catalog in Hyprland
  - Verify: nix eval .#homeConfigurations.hollowheap.config.desktop.shortcuts --apply 's: (builtins.hasAttr "close-window" s) && (builtins.hasAttr "focus-window-left" s) && (builtins.hasAttr "move-window-to-workspace" s)' | grep -qx true
  - Files: `home/modules/cli/shortcuts.nix`, `home/modules/gui/hyprland.nix`.
  - Notes: action names map to Hyprland dispatchers.
  - Risk: duplicate keybinds, unsupported action.

- [x] T19 [S20] (blocked-by: T17): Port the visual baseline into `home/modules/gui`
  - Verify: nix eval .#homeConfigurations.hollowheap.config.gtk.theme.name >/dev/null && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Files: `home/modules/gui`, `assets/`, `pkgs/`.
  - Notes: Hyprland, Noctalia, Wallust, styles, fonts, cursor, and dconf.
  - Risk: missing theme package, unresolved assets.

- [x] T20 [S18] (blocked-by: T01): Keep acervus awake with the lid closed and no charge cap
  - Verify: nix eval .#nixosConfigurations.acervus.config.services.logind.settings.Login.HandleLidSwitch | grep -qx ignore && nix eval .#nixosConfigurations.acervus.config.systemd.sleep.settings.Sleep.AllowSuspend | grep -qx no
  - Files: `hosts/acervus/default.nix`.
  - Notes: power policy belongs to the acervus host.
  - Risk: suspend on AC, battery cap reintroduced.

- [x] T21 [S21] (blocked-by: T17): Move PrismLauncher into the opt-in gaming bundle
  - Verify: test -f home/modules/apps/gaming/prismlauncher.nix && ! grep -R "prismlauncher" home/modules/cli
  - Files: `home/modules/apps/gaming/`, `home/modules/cli`.
  - Notes: bundles are explicit host or role imports.
  - Risk: PrismLauncher reaching CLI-only hosts.

- [x] T24 [S24] (blocked-by: T17): Add long-press and multi-finger hyprgrass gestures
  - Verify: grep -q 'kind = "longpress"' home/modules/gui/touch.nix
  - Files: `home/modules/gui/touch.nix`, `home/modules/gui/hyprland.nix`.
  - Notes: map gestures to window, launcher, and workspace actions.
  - Risk: gesture conflicts, unsupported actions.

- [x] T25 [S25] (blocked-by: none): Set the GRUB and Minegrub timeout to three seconds
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.loader.timeout | grep -qx 3 && grep -q "set timeout=3" pkgs/double-minegrub-menu.nix
  - Files: `boot/grub.nix`, `pkgs/double-minegrub-menu.nix`.
  - Notes: loader and packaged theme agree.
  - Risk: theme still ships 15 seconds.

- [x] T26 [S26] (blocked-by: none): Add i915 early KMS and fastboot to the Intel graphics trait
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.kernelModules | grep -q '"i915"' && nix eval .#nixosConfigurations.lacuna.config.boot.kernelParams | grep -q 'i915.fastboot=1'
  - Files: `hardware/graphics.nix`.
  - Notes: trait owns the module and parameter.
  - Risk: late KMS, panel reset.

- [x] T27 [S27] (blocked-by: none): Configure TPM2 unlock and PCR measurement in systemd initrd
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.tpm2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.boot.initrd.luks.devices.crypted.crypttabExtraOpts | grep -q "tpm2-device=auto"
  - Files: `boot/tpm.nix`.
  - Notes: `tpm_tis` and PCR phases are enabled.
  - Risk: missing firmware, passphrase-only boot.

- [x] T28 [S28] (blocked-by: T27): Sign GRUB and kernels with sbctl during install
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.extraInstallCommands | grep -q sbctl
  - Files: `boot/secure-boot.nix`.
  - Notes: signing runs from GRUB install hooks.
  - Risk: wrong EFI path, unsigned kernel.

- [x] T29 [S29] (blocked-by: T25): Keep Minegrub packages in pkgs and theme selection in boot
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.theme.name | grep -q double-minegrub-menu && test ! -e hardware/minegrub.nix
  - Files: `pkgs/double-minegrub-menu.nix`, `boot/minegrub.nix`.
  - Notes: only lacuna imports the theme.
  - Risk: hardware minegrub module, broken mainmenu path.

- [x] T30 [S30] (blocked-by: none): Enable PipeWire with ALSA and PulseAudio compatibility
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.pipewire.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.pipewire.pulse.enable | grep -qx true
  - Files: `roles/desktop/system/services.nix`.
  - Notes: 32-bit ALSA is enabled.
  - Risk: missing PulseAudio bridge.

- [x] T31 [S31] (blocked-by: none): Route DNS through systemd-resolved with Cloudflare DoT
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.resolved.extraConfig | grep -q "security.cloudflare-dns.com"
  - Files: `modules/services/network-services.nix`.
  - Notes: DNS-over-TLS is enforced.
  - Risk: plaintext fallback.

- [x] T32 [S32] (blocked-by: none): Configure NetworkManager with iwd and sops Wi-Fi profiles
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.networking.networkmanager.wifi.backend | grep -qx iwd && grep -q "wireless_env" hardware/wifi.nix
  - Files: `hardware/wifi.nix`.
  - Notes: profiles read `wireless_env`.
  - Risk: invalid key-mgmt, missing secret.

- [x] T33 [S33] (blocked-by: none): Enable udisks2, gvfs, and usbmuxd
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.udisks2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.gvfs.enable | grep -qx true
  - Files: `roles/desktop/system/services.nix`.
  - Notes: desktop media and iOS access.
  - Risk: root-only mounts.

- [x] T34 [S34] (blocked-by: none): Keep thermald, upower, and power-profiles-daemon in the laptop profile
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.thermald.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.upower.enable | grep -qx true
  - Files: `profiles/laptop/default.nix`.
  - Notes: chassis policy only.
  - Risk: hardware traits owning policy.

- [x] T35 [S35] (blocked-by: none): Keep recursive module discovery in lib/default.nix
  - Verify: grep -q "mkModuleLoader" modules/default.nix && test -f lib/default.nix
  - Files: `lib/default.nix`, `modules/default.nix`.
  - Notes: new modules are discovered automatically.
  - Risk: manual import drift.

- [x] T36 [S36] (blocked-by: none): Keep the local package overlay recursive
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.double-minegrub-menu.name | grep -q double-minegrub-menu && grep -q "kebabToCamel" pkgs/default.nix
  - Files: `pkgs/default.nix`, `pkgs/`.
  - Notes: file names stay kebab, directory scopes camelCase.
  - Risk: missing package, broken scope.

- [x] T37 [S37] (blocked-by: none): Expose every language devShell and alias
  - Verify: for s in default ts c rust python pico nix typescript js clang cpp; do nix eval .#devShells.x86_64-linux.$s.name >/dev/null || exit 1; done
  - Files: `flake/devshells.nix`, `flake/default.nix`.
  - Notes: shells stay flake-local.
  - Risk: missing alias, stale package.

- [x] T38 [S38] (blocked-by: none): Trust the Termux, community, and Hyprland Cachix caches
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "nix-on-droid.cachix.org" && nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "hyprland.cachix.org"
  - Files: `modules/system/cachix.nix`.
  - Notes: cache.nixos.org stays default.
  - Risk: missing public key.

- [x] T39 [S39] (blocked-by: T10): Keep server ingress ports with the Headscale role
  - Verify: grep -q "Headscale ingress" roles/server/system/default.nix && grep -q "allowedUDPPorts = \[ 3478 \]" roles/server/system/default.nix
  - Files: `roles/server/system/default.nix`.
  - Notes: ports 80/443 and 3478.
  - Risk: ports in generic modules.

- [x] T40 [S40] (blocked-by: none): Enable BTRFS scrub, zram, and explicit mount options
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.btrfs.autoScrub.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.zramSwap.enable | grep -qx true
  - Files: `hardware/filesystems.nix`.
  - Notes: monthly scrub and zram swap.
  - Risk: missing scrub, lost mount flags.

- [x] T41 [S41] (blocked-by: T14): Move flake checks into `tests/` and split them by domain
  - Verify: nix build .#checks.x86_64-linux.layout .#checks.x86_64-linux.policy .#checks.x86_64-linux.hardware .#checks.x86_64-linux.home .#checks.x86_64-linux.services .#checks.x86_64-linux.users
  - Files: `tests/default.nix`, `tests/{layout,policy,hardware,home,services,users}.nix`, `flake/default.nix`.
  - Notes: `tests/default.nix` recursively imports domain files; flake only imports the tests tree.
  - Risk: duplicate domain names, missing test file, stale path checks.

- [x] T42 [S42] (blocked-by: T17): Port zsh, zoxide, git, direnv, tealdeer, and core terminal tools into `home/modules/cli`
  - Verify: test -f home/modules/cli/zsh.nix && nix eval .#homeConfigurations.hollowheap.config.programs.zsh.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.programs.eza.enable | grep -qx true
  - Files: `home/modules/cli/{zsh,zoxide,tools,git,ssh,direnv,tealdeer}.nix`, `home/cli.nix`.
  - Notes: zsh-fzf-tab-source was dropped because the sibling module referenced an undefined `zshPlugins`.
  - Risk: duplicate options, custom package missing from nixpkgs.

- [x] T43 [S43] (blocked-by: T42): Port starship, tmux, and wallust-themed bat/btop/yazi/lazygit config after sharing style options with CLI
  - Verify: test -f home/modules/cli/starship.nix
  - Files: `home/modules/cli/starship.nix`, `home/modules/cli/tmux.nix`, `home/modules/cli/{bat,btop,yazi,lazygit}.nix`.
  - Notes: move `styles.pills` and wallust templates into the CLI tier or a shared base first.
  - Risk: GUI-only theme dependency, duplicate options.

- [x] T44 [S43] (blocked-by: T42): Port GUI app modules into opt-in `home/modules/apps/gui` bundles
  - Verify: test -f home/modules/apps/gui/ghostty.nix
  - Files: `home/modules/apps/gui/{ghostty,zen-browser,vesktop,thunderbird,obs-studio,pear-desktop}.nix`.
  - Notes: keep each app optional and absent from CLI-only hosts.
  - Risk: missing external flake modules, GUI leakage into CLI.

- [x] T45 [S43] (blocked-by: T42): Port opencode and the AI option schema into `home/modules/cli`
  - Verify: test -f home/modules/cli/opencode.nix && nix eval .#homeConfigurations.hollowheap.config.programs.opencode.enable | grep -qx true
  - Files: `home/modules/cli/{opencode,ai-options,ai-render,opencode-ai-hooks.ts}`, `home/cli.nix`.
  - Notes: AI agents/skills content and nvim/nvf remain separate slices.
  - Risk: HM opencode option drift, wallust template path.

## Open

- [ ] T22 [S22] (blocked-by: T10): Add DuckDNS DNS-01 for publicly trusted Caddy certificates
  - Verify: grep -q "dns duckdns" roles/server/system/default.nix
  - Files: `roles/server/system/default.nix`, `flake.nix`, `secrets.yaml`.
  - Notes: only the public baseDomain vhost uses DNS-01; loopback Headscale/Vaultwarden still use internal TLS. Runtime issuance untested.
  - Risk: missing token, DuckDNS subdomain delegation, plugin hash mismatch.

- [ ] T23 [S23] (blocked-by: T01): Make passwords and SSH keys declarative through sops
  - Verify: nix eval .#nixosConfigurations.lacuna.config.users.users.hollowheap.hashedPasswordFile >/dev/null
  - Files: `modules/system/users.nix`, `secrets.yaml`, `.sops.yaml`.
  - Notes: Deferred until hollowheap's password hash and SSH keys are supplied; steve remains a non-admin test user. Disable mutable users only after keys are declared.
  - Risk: account lockout, missing secret.

- [x] T46 [S43] (blocked-by: T42): Port auxiliary services and core environment modules
  - Verify: test -f home/modules/cli/services.nix
  - Files: `home/modules/cli/{services-auth-agents,rclone,store-hygiene,env,accounts,packages}.nix`.
  - Notes: keep GUI-only services out of CLI.
  - Risk: service assumptions, missing packages.

- [x] T47 [S43] (blocked-by: T42): Port default apps and remaining shell utilities
  - Verify: test -f home/modules/cli/default-apps.nix
  - Files: `home/modules/cli/{default-apps,utilities,fastfetch}.nix`.
  - Notes: mimeApps defaults, delta/wallust-free utilities, fastfetch.
  - Risk: references to missing GUI apps, duplicate options.

- [x] T76 [S43] (blocked-by: T45): Port nvim/nvf modules into `home/modules/cli`
  - Verify: test -f home/modules/cli/nvim.nix
  - Files: `home/modules/cli/nvim/*.nix`, `flake.nix`.
  - Notes: requires the nvf input and the wallust nvim template.
  - Risk: large closure, nvf option drift.

- [x] T77 [S43] (blocked-by: T45): Port AI agents, disciplines, rules, skills, and hooks content
  - Verify: test -f home/modules/cli/ai-agents.nix
  - Files: `home/modules/cli/ai/{agents,disciplines,rules,skills,hooks}.nix`.
  - Notes: fills the schema ported in T45 with the actual prompt/skill content.
  - Risk: prompt drift, missing skill assets.

- [x] T78 [S47] (blocked-by: none): Extract Neovim quickfix, preview, and editing domain modules
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/programs/nvim/{quickfix,preview,editing,debugger,core,keymaps}.nix`, `home/modules/programs/nvim.nix`.
  - Notes: Co-locate lazy plugin definitions, whichKey registrations, and keymaps; remove them from `core.nix` and `keymaps.nix`.
  - Risk: keybinding conflicts or syntax errors in nvf Lua configurations.

- [x] T79 [S48] (blocked-by: none): Encode universal harness clamps and partition eager/lazy skills
  - Verify: nix build .#checks.x86_64-linux.home && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/ai/rules.nix`, `home/modules/ai/agents.nix`, `artifacts/decisions.md`.
  - Notes: Generalize empirical retro failure modes into framework-agnostic clamps (runner check, exact verify, gate integrity, experiment timebox, subagent caps); prune 7 domain skills from primary `engineer` agent to slim eager prompt footprint.
  - Risk: capability mismatch or broken subagent skill availability.

- [x] T80 [S49] (blocked-by: none): Consolidate frontend micro-skills into ui-author and ui-audit umbrella skills
  - Verify: test -f assets/skills/review/references/ui.md
  - Files: `home/modules/ai/skills.nix`, `home/modules/ai/agents.nix`, `artifacts/decisions.md`.
  - Notes: Superseded by review absorption; UI authoring and audit guidance now lives in `assets/skills/review/references/ui.md`.
  - Risk: missing references or broken schema generation.

- [x] T81 [S50] (blocked-by: none): Author and wire backend-author and modular-design umbrella skills
  - Verify: test -f assets/skills/review/references/backend.md && test -f assets/skills/modular-design/SKILL.md
  - Files: `home/modules/ai/skills.nix`, `home/modules/ai/agents.nix`, `artifacts/decisions.md`, `artifacts/specs.md`.
  - Notes: Superseded by review absorption; backend guidance now lives in `assets/skills/review/references/backend.md`, while `modular-design` remains a standalone skill.
  - Risk: missing reference patterns or broken schema generation.

- [x] T82 [S51] (blocked-by: none): Align harness model routing and reasoning effort
  - Verify: nix build .#checks.x86_64-linux.home && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/programs/codex.nix`, `home/modules/programs/kiro-cli.nix`, `home/modules/ai/options.nix`, `artifacts/decisions.md`, `artifacts/specs.md`.
  - Notes: Codify `gpt-6-luna` (xhigh) for Codex settings and agent profiles; map Kiro agents to `claude-sonnet-5.5` (low) for high tier and `claude-haiku-5.5` (xhigh) for medium/low tiers; switch global `ai.tiers` default to `opencode-go`.
  - Risk: invalid JSON/TOML keys or broken Home Manager generation.

- [x] T83 [S52] (blocked-by: none): Declarative dynamic Bitwarden/rbw key delivery for AI harnesses
  - Verify: home-manager switch --flake .#hollowheap
  - Files: `home/modules/shell/zsh.nix`, `home/modules/programs/opencode.nix`, `home/modules/programs/pi-coding-agent.nix`, `pkgs/ai-hooks.nix`.
  - Notes: Zsh automatically exports `OPENCODE_API_KEY` on shell startup and dynamically in a `preexec` hook before AI harness commands; OpenCode config explicitly searches for `OPENCODE_API_KEY`; Pi natively resolves keys using dynamic `!rbw get` execution via declarative `auth.json`; `ai-hooks.nix` guards session-start against non-git scans with a 5s timeout.
  - Risk: locked vault at invocation, clobbered auth files on activation.

- [x] T84 [S53] (blocked-by: none): Declare XDG user directories and unify Wallust template directory
  - Verify: home-manager switch --flake .#hollowheap
  - Files: `home/modules/environment/session.nix`, `home/modules/programs/wallust.nix`, `home/modules/programs/noctalia.nix`.
  - Notes: `xdg.userDirs` declares standard directories while redirecting templates, desktop, and publicShare into `~/.local/share/`; Wallust templates deploy into `${config.xdg.userDirs.templates}` and mirror to `~/.config/wallust/templates`; Noctalia invokes Wallust with `--templates-dir`.
  - Risk: missing directories or broken template path.

- [x] T85 [S54] (blocked-by: none): Decompose server system role into vertical slices
  - Verify: nix build .#checks.x86_64-linux.services && nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run
  - Files: `roles/server/system/{default,caddy,headscale,vaultwarden,ddclient,domains}.nix`, `tests/services.nix`.
  - Notes: Extract `caddy.nix`, `headscale.nix`, `vaultwarden.nix`, `ddclient.nix`, and `domains.nix`; update `roles/server/system/default.nix` to aggregate; update `tests/services.nix` assertions.
  - Risk: broken reverse proxy configuration, unmerged vhosts, failed NixOS dry-run.

- [x] T86 [S55] (blocked-by: T85): Reorganize home modules into terminal, cli, and programs taxonomy
  - Verify: nix build .#checks.x86_64-linux.home && nix build .#checks.x86_64-linux.layout && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/{terminal,cli,programs}/`, `tests/home.nix`, `AGENTS.md`.
  - Notes: Move shell & multiplexers into `terminal/`, standalone utilities into `cli/`, keep GUI apps & harnesses in `programs/`; update `tests/home.nix` and `AGENTS.md`.
  - Risk: path mismatch in tests, broken imports, missing symlinks.

- [x] T87 [S56] (blocked-by: none): Author OMP harness module and wire flake inputs and ai.* abstractions
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `flake.nix`, `flake/default.nix`, `home/modules/programs/omp.nix`, `home/modules/ai/options.nix`, `pkgs/ai-hooks.nix`.
  - Notes: Add `inputs.omp` pointing to `github:can1357/oh-my-pi`; import `inputs.omp.homeManagerModules.default` in `flake/default.nix`; create `home/modules/programs/omp.nix` deploying skills, agents, disciplines, rules, and hooks into `~/.omp/agent/`; update `pkgs/ai-hooks.nix` and `home/modules/ai/options.nix`.
  - Risk: flake lock resolution time, bun/rust dependency mismatches.

- [x] T88 [S57] (blocked-by: none): Configure Pi settings to exclude tool-search, mcp, and llama.cpp built-ins
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.pi-coding-agent.settings.extensions && nix build .#checks.x86_64-linux.home
  - Files: `home/modules/programs/pi-coding-agent.nix`, `tests/home.nix`.
  - Notes: Add `extensions = [ "-builtin:tool-search" "-builtin:mcp" "-builtin:llama.cpp" ];` to `programs.pi-coding-agent.settings` and verify via HM eval and domain checks.
  - Risk: none.

- [x] T89 [S58] (blocked-by: none): Wire Noctalia wallpaper hook directly to Wallust and icon/GTK accent dispatchers
  - Verify: nix eval .#homeConfigurations.hollowheap.config.programs.noctalia.settings.hooks.wallpaper_changed | grep -q "mactahoe-icon-accent" && nix build .#checks.x86_64-linux.home
  - Files: `home/modules/programs/noctalia.nix`, `home/modules/programs/wallust.nix`, `home/modules/programs/hyprland/hyprland.nix`, `assets/wallust-templates/hypr-colors.lua`, `pkgs/mactahoe-icon-accent.py`, `pkgs/mactahoe-icon-accent.nix`.
  - Notes: Replace Noctalia stub user templates with direct wallpaper_changed hook execution of Wallust, GTK accent, icon accent, and OpenRGB; migrate Hyprland border template to Wallust; update mactahoe-icon-accent to sync dconf, gsettings, and GTK settings.ini.
  - Risk: none.

- [x] T90 [S59] (blocked-by: none): Integrate diagram.nvim and image.nvim with CLI renderers in Neovim
  - Verify: nix eval --raw '.#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.lazy.plugins."diagram.nvim".setupModule' | grep -q "diagram" && nix build .#checks.x86_64-linux.home
  - Files: `home/modules/programs/nvim/diagrams.nix`, `home/modules/programs/nvim.nix`, `flake/default.nix`, `tests/home.nix`.
  - Notes: Add `"diagram.nvim"` to `allowUnfreePredicate`; author `home/modules/programs/nvim/diagrams.nix` configuring `image.nvim` (kitty protocol, eager start plugin), `diagram.nvim` (lazy plugin, markdown/neorg integrations), CLI tools (`imagemagick`, `mermaid-cli`, `plantuml`, `d2`, `graphviz`), and `<leader>m` bindings; import in `nvim.nix`; update `tests/home.nix`.
  - Risk: none.

- [x] T91 [S60] (blocked-by: none): Author on-demand retro skill in home/modules/ai/skills.nix
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.retro.description | grep -q "retrospective" && test -f home/modules/ai/skills.nix
  - Files: `home/modules/ai/skills.nix`, `artifacts/retro.md`.
  - Notes: Define `retro` skill with 5-step workflow inspecting active `transcript.jsonl`, quantifying metrics, checking rule compliance, and emitting to `artifacts/retro.md`.
  - Risk: none.

- [x] T92 [S61] (blocked-by: none): Author corpus-audit skill in home/modules/ai/skills.nix
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.corpus-audit.description | grep -q "corpus-audit" && test -f home/modules/ai/skills.nix
  - Files: `home/modules/ai/skills.nix`.
  - Notes: Define `corpus-audit` skill ingesting multi-session logs across past runs and SQLite logs, auditing workspace blind spots, cognitive traps, and tool waste into `artifacts/audit.md`.
  - Risk: none.

## References
- Requirements: [artifacts/requirements.md](file:///home/hollowheap/repos/nixos-config/artifacts/requirements.md)
- Decisions: [artifacts/decisions.md](file:///home/hollowheap/repos/nixos-config/artifacts/decisions.md)
- Specifications: [artifacts/specs.md](file:///home/hollowheap/repos/nixos-config/artifacts/specs.md)
