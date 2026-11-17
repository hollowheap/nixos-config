# Tasks

Active tasks, completed history, and verification commands. Requirements live in `.artifacts/REQUIREMENTS.md`; decisions in `.artifacts/DECISIONS.md`; invariants in `.artifacts/SPECS.md`.

### Completed — Restored historical range

- [x] T48 [S35] (blocked-by: none): Extract shared module discovery to `lib/default.nix`
  - Verify: grep -q "mkModuleLoader" modules/default.nix
  - Files: restored historical change.
  - Notes: current equivalent is part of the S35 contract.
  - Risk: stale option or path.
  - Detail: tasks/T48.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T49 [S36] (blocked-by: none): Port recursive package discovery to `pkgs/default.nix`
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.double-minegrub-menu.name | grep -q double-minegrub-menu
  - Files: restored historical change.
  - Notes: current equivalent is part of the S36 contract.
  - Risk: stale option or path.
  - Detail: tasks/T49.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T50 [S01] (blocked-by: none): Modularize flake outputs into `flake/default.nix`
  - Verify: test -f flake/default.nix
  - Files: restored historical change.
  - Notes: current equivalent is part of the S01 contract.
  - Risk: stale option or path.
  - Detail: tasks/T50.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T51 [S01] (blocked-by: none): Standardize repo skills under `skills/`
  - Verify: test -d skills/nix-flake-eval
  - Files: restored historical change.
  - Notes: current equivalent is part of the S01 contract.
  - Risk: stale option or path.
  - Detail: tasks/T51.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T52 [S37] (blocked-by: none): Add the maintenance devShell
  - Verify: nix eval .#devShells.x86_64-linux.default.name >/dev/null
  - Files: restored historical change.
  - Notes: current equivalent is part of the S37 contract.
  - Risk: stale option or path.
  - Detail: tasks/T52.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T53 [S17] (blocked-by: none): Deploy rootless Podman
  - Verify: nix eval .#nixosConfigurations.lacuna.config.virtualisation.podman.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S17 contract.
  - Risk: stale option or path.
  - Detail: tasks/T53.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T54 [S17] (blocked-by: none): Expose the Docker socket
  - Verify: nix eval .#nixosConfigurations.lacuna.config.virtualisation.podman.dockerSocket.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S17 contract.
  - Risk: stale option or path.
  - Detail: tasks/T54.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T55 [S17] (blocked-by: none): Enable container DNS resolution
  - Verify: nix eval .#nixosConfigurations.lacuna.config.virtualisation.podman.defaultNetwork.settings.dns_enabled | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S17 contract.
  - Risk: stale option or path.
  - Detail: tasks/T55.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T56 [S17] (blocked-by: none): Grant the podman group through the admin seam
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.extraGroups | grep -q podman
  - Files: restored historical change.
  - Notes: current equivalent is part of the S17 contract.
  - Risk: stale option or path.
  - Detail: tasks/T56.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T57 [S06] (blocked-by: none): Silence console boot noise
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.consoleLogLevel | grep -qx 0
  - Files: restored historical change.
  - Notes: current equivalent is part of the S06 contract.
  - Risk: stale option or path.
  - Detail: tasks/T57.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T58 [S11] (blocked-by: none): Silence UWSM startup output
  - Verify: nix eval .#nixosConfigurations.lacuna.config.environment.sessionVariables.UWSM_SILENT_START | grep -qx 2
  - Files: restored historical change.
  - Notes: current equivalent is part of the S11 contract.
  - Risk: stale option or path.
  - Detail: tasks/T58.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T59 [S05] (blocked-by: none): Decouple the Nvidia driver stack
  - Verify: nix eval .#nixosConfigurations.acervus.config.hardware.nvidia.modesetting.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S05 contract.
  - Risk: stale option or path.
  - Detail: tasks/T59.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T60 [S26] (blocked-by: none): Enable Intel microcode
  - Verify: nix eval .#nixosConfigurations.lacuna.config.hardware.cpu.intel.updateMicrocode | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S26 contract.
  - Risk: stale option or path.
  - Detail: tasks/T60.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T61 [S07] (blocked-by: none): Declare the Disko GPT/LUKS/BTRFS layout
  - Verify: nix eval .#nixosConfigurations.lacuna.config.disko.devices.disk.main.type | grep -qx disk
  - Files: restored historical change.
  - Notes: current equivalent is part of the S07 contract.
  - Risk: stale option or path.
  - Detail: tasks/T61.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T62 [S27] (blocked-by: none): Enable TPM2 systemd initrd unlock
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.tpm2.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S27 contract.
  - Risk: stale option or path.
  - Detail: tasks/T62.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T63 [S28] (blocked-by: none): Add Secure Boot signing hooks
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.extraInstallCommands | grep -q sbctl
  - Files: restored historical change.
  - Notes: current equivalent is part of the S28 contract.
  - Risk: stale option or path.
  - Detail: tasks/T63.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T64 [S30] (blocked-by: none): Enable PipeWire audio
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.pipewire.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S30 contract.
  - Risk: stale option or path.
  - Detail: tasks/T64.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T65 [S31] (blocked-by: none): Enable DNS-over-TLS
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.resolved.extraConfig | grep -q security.cloudflare-dns.com
  - Files: restored historical change.
  - Notes: current equivalent is part of the S31 contract.
  - Risk: stale option or path.
  - Detail: tasks/T65.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T66 [S32] (blocked-by: none): Use NetworkManager with iwd
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.networking.networkmanager.wifi.backend | grep -qx iwd
  - Files: restored historical change.
  - Notes: current equivalent is part of the S32 contract.
  - Risk: stale option or path.
  - Detail: tasks/T66.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T67 [S10] (blocked-by: none): Decrypt host secrets with the SSH age key
  - Verify: nix eval .#nixosConfigurations.lacuna.config.sops.defaultSopsFormat | grep -qx yaml
  - Files: restored historical change.
  - Notes: current equivalent is part of the S10 contract.
  - Risk: stale option or path.
  - Detail: tasks/T67.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T68 [S33] (blocked-by: none): Enable removable-media daemons
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.udisks2.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S33 contract.
  - Risk: stale option or path.
  - Detail: tasks/T68.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T69 [S34] (blocked-by: none): Enable laptop power management
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.thermald.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S34 contract.
  - Risk: stale option or path.
  - Detail: tasks/T69.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T70 [S40] (blocked-by: none): Enable BTRFS autoScrub
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.btrfs.autoScrub.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S40 contract.
  - Risk: stale option or path.
  - Detail: tasks/T70.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T71 [S08] (blocked-by: none): Deploy Headscale and Caddy
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.headscale.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S08 contract.
  - Risk: stale option or path.
  - Detail: tasks/T71.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T72 [S08] (blocked-by: none): Deploy loopback Vaultwarden
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.vaultwarden.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S08 contract.
  - Risk: stale option or path.
  - Detail: tasks/T72.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T73 [S11] (blocked-by: none): Deploy Noctalia greeter
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.enable | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S11 contract.
  - Risk: stale option or path.
  - Detail: tasks/T73.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T74 [S11] (blocked-by: none): Enable Hyprland with UWSM
  - Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S11 contract.
  - Risk: stale option or path.
  - Detail: tasks/T74.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T75 [S01] (blocked-by: none): Enable weekly Nix GC and optimisation
  - Verify: nix eval .#nixosConfigurations.lacuna.config.nix.settings.auto-optimise-store | grep -qx true
  - Files: restored historical change.
  - Notes: current equivalent is part of the S01 contract.
  - Risk: stale option or path.
  - Detail: tasks/T75.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

### Completed — Current implementation

- [x] T01 [S01] (blocked-by: none): Merge Home Manager into `home/` and expose NixOS and standalone outputs
  - Verify: nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath >/dev/null && nix eval .#nixosConfigurations.lacuna.config.system.build.toplevel.drvPath >/dev/null
  - Files: `flake.nix`, `flake/default.nix`, `home/`, `hosts/lacuna/default.nix`.
  - Notes: copied the current Home Manager visual modules from the sibling repository.
  - Risk: missing input, divergent option sets.
  - Detail: tasks/T01.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T02 [S03] (blocked-by: T01): Generate hosts from `hosts/<name>/default.nix` and compose profiles, roles, and traits
  - Verify: grep -q "profiles/laptop" hosts/lacuna/default.nix && grep -q "roles/server/system" hosts/lacuna/default.nix && test -f hosts/lacuna/hardware.nix
  - Files: `flake/default.nix`, `hosts/lacuna`, `hosts/acervus`.
  - Notes: host-local `hardware.nix` groups traits; `boot.nix` groups boot components.
  - Risk: double profile imports, hidden hardware in profiles.
  - Detail: tasks/T02.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T03 [S02] (blocked-by: T01): Keep NixOS on release-26.05 and standalone Home Manager on unstable
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.lib.version | grep -q "26\.05" && nix eval --raw .#homeConfigurations.hollowheap.pkgs.lib.version | grep -q "26\.11"
  - Files: `flake.nix`, `modules/system/nixpkgs.nix`, `flake/default.nix`.
  - Notes: standalone Home Manager evaluates with unstable pkgs; NixOS does not import the HM module.
  - Risk: unstable drivers leaking into NixOS.
  - Detail: tasks/T03.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T04 [S06] (blocked-by: T01): Split boot into kernel, GRUB, TPM, Secure Boot, Minegrub, and Plymouth modules
  - Verify: for f in grub tpm secure-boot minegrub kernel plymouth; do test -f boot/$f.nix; done && test ! -e modules/boot/boot.nix
  - Files: `boot/`, `hosts/lacuna/boot.nix`, `hosts/acervus/boot.nix`.
  - Notes: hosts import only the boot components they use.
  - Risk: missing GRUB or TPM module, duplicate boot settings.
  - Detail: tasks/T04.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T05 [S07] (blocked-by: T01): Keep the Disko LUKS/BTRFS layout in the lacuna host
  - Verify: test -f hosts/lacuna/disko.nix && nix eval .#nixosConfigurations.lacuna.config.disko.devices.disk.main.type | grep -qx disk
  - Files: `hosts/lacuna/disko.nix`.
  - Notes: acervus keeps a placeholder until installation.
  - Risk: unencrypted root, missing subvolumes.
  - Detail: tasks/T05.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T06 [S04] (blocked-by: T01): Gate touch and HDR through hardware flags in the standalone Home Manager output
  - Verify: grep -q "desktop.touch = true" hardware/touch.nix && grep -q "desktop.hdr = true" hardware/hdr.nix && grep -q "desktop.touch = true" home/hollowheap.nix && grep -Rq "config.desktop.touch" home/modules/gui
  - Files: `hardware/touch.nix`, `hardware/hdr.nix`, `home/modules/cli/desktop-options.nix`, `home/modules/gui/touch.nix`, `home/modules/gui/hdr.nix`, `flake/default.nix`.
  - Notes: standalone HM sets the flags directly; NixOS no longer imports Home Manager.
  - Risk: missing flag, compositor ignoring it.
  - Detail: tasks/T06.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T07 [S05] (blocked-by: T06): Keep lacuna Intel-only and import hybrid Intel + Nvidia on acervus
  - Verify: grep -q "hybrid-gpu" hosts/acervus/default.nix && ! grep -q "hybrid-gpu" hosts/lacuna/hardware.nix && nix eval .#nixosConfigurations.acervus.config.hardware.nvidia.prime.offload.enable | grep -qx true
  - Files: `hardware/nvidia.nix`, `hardware/hybrid-gpu.nix`, `hosts/acervus/default.nix`.
  - Notes: Nvidia unfree names live in the Nvidia trait.
  - Risk: driver/kernel mismatch, stale PRIME bus IDs.
  - Detail: tasks/T07.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T08 [S17] (blocked-by: T01): Add `users.adminExtraGroups` and let modules own their groups
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.extraGroups | grep -q '"podman"' && ! grep -q '"podman"' modules/system/users.nix
  - Files: `modules/options/users.nix`, `modules/system/users.nix`, `modules/virtualisation/podman.nix`, `hardware/wifi.nix`, `hardware/rgb.nix`, `boot/tpm.nix`, `hardware/graphics.nix`.
  - Notes: Podman, Wi-Fi, RGB, TPM, and graphics append groups.
  - Risk: stale groups on hosts that omit a module.
  - Detail: tasks/T08.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T09 [S16] (blocked-by: T03): Replace the hardcoded unfree list with a declarable `unfreePackages` option
  - Verify: nix eval .#nixosConfigurations.lacuna.config.unfreePackages --apply 'ps: builtins.elem "steam" ps' | grep -qx true && grep -q "config.unfreePackages" modules/system/nixpkgs.nix
  - Files: `modules/options/unfree.nix`, `modules/system/nixpkgs.nix`, `hardware/nvidia.nix`.
  - Notes: owning modules append their package names.
  - Risk: predicate not applied to the unstable set.
  - Detail: tasks/T09.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T10 [S08] (blocked-by: T01): Run Headscale, Vaultwarden, Caddy, and ddclient from the lacuna server role
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services --apply 's: map (n: s.${n}.enable or false) [ "headscale" "vaultwarden" "caddy" "ddclient" ]' | grep -qx '\[true,true,true,true\]'
  - Files: `roles/server/system/default.nix`, `hosts/lacuna/default.nix`.
  - Notes: acervus does not import the server role yet.
  - Risk: duplicated services, acervus running the vault.
  - Detail: tasks/T10.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T11 [S09] (blocked-by: T10): Use Caddy internal TLS for loopback names and point tailscaled at its CA
  - Verify: grep -q "tls internal" roles/server/system/default.nix && grep -q "SSL_CERT_FILE" roles/server/system/default.nix
  - Files: `roles/server/system/default.nix`.
  - Notes: DNS-01 remains a future task.
  - Risk: untrusted CA, ACME retries.
  - Detail: tasks/T11.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T12 [S10] (blocked-by: T01): Rekey sops to lacuna's age key, keep admin PGP recovery, and install secrets via systemd
  - Verify: grep -q "&lacuna age1cum" .sops.yaml && grep -q "recipient: age1cum" secrets.yaml && nix eval .#nixosConfigurations.lacuna.config.sops.useSystemdActivation | grep -qx true
  - Files: `.sops.yaml`, `secrets.yaml`, `modules/security/sops.nix`.
  - Notes: `sops updatekeys --yes` completed; activation decrypts at boot.
  - Risk: wrong recipient, lost recovery key.
  - Detail: tasks/T12.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T13 [S19] (blocked-by: T12): Restore `vaultwarden_env` and generate an admin token
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.services.vaultwarden.environmentFile | grep -q "/run/secrets/vaultwarden_env" && grep -q "vaultwarden_env:" secrets.yaml
  - Files: `roles/server/system/default.nix`, `secrets.yaml`.
  - Notes: token is generated and retrievable with `sops decrypt --extract`.
  - Risk: missing env file, token in git.
  - Detail: tasks/T13.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T14 [S15] (blocked-by: T01): Add the flake checks
  - Verify: nix flake check
  - Files: `flake/default.nix`.
  - Notes: checks profile, role, hardware, boot, Home Manager, and Termux paths.
  - Risk: stale path checks, missing files.
  - Detail: tasks/T14.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T15 [S14] (blocked-by: T01): Add the `fovea` nix-on-droid output
  - Verify: nix eval .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx "24.05" && test ! -d hosts/fovea
  - Files: `flake.nix`, `flake/default.nix`, `nix-on-droid.nix`.
  - Notes: output uses unstable aarch64 and stays outside host enumeration.
  - Risk: missing input, host directory collision.
  - Detail: tasks/T15.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T16 [S11] (blocked-by: T01): Keep the system session and wire Home Manager user configuration
  - Verify: nix eval .#nixosConfigurations.lacuna.config.programs.hyprland.withUWSM | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Files: `roles/desktop/system/default.nix`, `flake/default.nix`, `home/modules/gui`.
  - Notes: system owns greeter, package, and portals.
  - Risk: double compositor, missing greeter.
  - Detail: tasks/T16.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T17 [S12] (blocked-by: T16): Split `home/modules/cli` and `home/modules/gui`
  - Verify: ! grep -R "home/modules/gui" home/modules/cli && grep -Rq "launchApp" home/modules/cli && grep -Rq "defaultApps" home/modules/cli
  - Files: `home/modules/cli`, `home/modules/gui`, `home/cli.nix`, `home/gui.nix`.
  - Notes: shared options live in the CLI tier.
  - Risk: GUI leakage into CLI, duplicate options.
  - Detail: tasks/T17.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T18 [S13] (blocked-by: T17): Render the neutral shortcut catalog in Hyprland
  - Verify: nix eval .#homeConfigurations.hollowheap.config.desktop.shortcuts --apply 's: (builtins.hasAttr "close-window" s) && (builtins.hasAttr "focus-window-left" s) && (builtins.hasAttr "move-window-to-workspace" s)' | grep -qx true
  - Files: `home/modules/cli/shortcuts.nix`, `home/modules/gui/hyprland.nix`.
  - Notes: action names map to Hyprland dispatchers.
  - Risk: duplicate keybinds, unsupported action.
  - Detail: tasks/T18.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T19 [S20] (blocked-by: T17): Port the visual baseline into `home/modules/gui`
  - Verify: nix eval .#homeConfigurations.hollowheap.config.gtk.theme.name >/dev/null && nix eval .#homeConfigurations.hollowheap.config.wayland.windowManager.hyprland.enable | grep -qx true
  - Files: `home/modules/gui`, `assets/`, `pkgs/`.
  - Notes: Hyprland, Noctalia, Wallust, styles, fonts, cursor, and dconf.
  - Risk: missing theme package, unresolved assets.
  - Detail: tasks/T19.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T20 [S18] (blocked-by: T01): Keep acervus awake with the lid closed and no charge cap
  - Verify: nix eval .#nixosConfigurations.acervus.config.services.logind.settings.Login.HandleLidSwitch | grep -qx ignore && nix eval .#nixosConfigurations.acervus.config.systemd.sleep.settings.Sleep.AllowSuspend | grep -qx no
  - Files: `hosts/acervus/default.nix`.
  - Notes: power policy belongs to the acervus host.
  - Risk: suspend on AC, battery cap reintroduced.
  - Detail: tasks/T20.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T21 [S21] (blocked-by: T17): Move PrismLauncher into the opt-in gaming bundle
  - Verify: test -f home/modules/apps/gaming/prismlauncher.nix && ! grep -R "prismlauncher" home/modules/cli
  - Files: `home/modules/apps/gaming/`, `home/modules/cli`.
  - Notes: bundles are explicit host or role imports.
  - Risk: PrismLauncher reaching CLI-only hosts.
  - Detail: tasks/T21.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T24 [S24] (blocked-by: T17): Add long-press and multi-finger hyprgrass gestures
  - Verify: grep -q 'kind = "longpress"' home/modules/gui/touch.nix
  - Files: `home/modules/gui/touch.nix`, `home/modules/gui/hyprland.nix`.
  - Notes: map gestures to window, launcher, and workspace actions.
  - Risk: gesture conflicts, unsupported actions.
  - Detail: tasks/T24.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T25 [S25] (blocked-by: none): Set the GRUB and Minegrub timeout to three seconds
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.loader.timeout | grep -qx 3 && grep -q "set timeout=3" pkgs/double-minegrub-menu.nix
  - Files: `boot/grub.nix`, `pkgs/double-minegrub-menu.nix`.
  - Notes: loader and packaged theme agree.
  - Risk: theme still ships 15 seconds.
  - Detail: tasks/T25.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T26 [S26] (blocked-by: none): Add i915 early KMS and fastboot to the Intel graphics trait
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.kernelModules | grep -q '"i915"' && nix eval .#nixosConfigurations.lacuna.config.boot.kernelParams | grep -q 'i915.fastboot=1'
  - Files: `hardware/graphics.nix`.
  - Notes: trait owns the module and parameter.
  - Risk: late KMS, panel reset.
  - Detail: tasks/T26.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T27 [S27] (blocked-by: none): Configure TPM2 unlock and PCR measurement in systemd initrd
  - Verify: nix eval .#nixosConfigurations.lacuna.config.boot.initrd.systemd.tpm2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.boot.initrd.luks.devices.crypted.crypttabExtraOpts | grep -q "tpm2-device=auto"
  - Files: `boot/tpm.nix`.
  - Notes: `tpm_tis` and PCR phases are enabled.
  - Risk: missing firmware, passphrase-only boot.
  - Detail: tasks/T27.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T28 [S28] (blocked-by: T27): Sign GRUB and kernels with sbctl during install
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.extraInstallCommands | grep -q sbctl
  - Files: `boot/secure-boot.nix`.
  - Notes: signing runs from GRUB install hooks.
  - Risk: wrong EFI path, unsigned kernel.
  - Detail: tasks/T28.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T29 [S29] (blocked-by: T25): Keep Minegrub packages in pkgs and theme selection in boot
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.boot.loader.grub.theme.name | grep -q double-minegrub-menu && test ! -e hardware/minegrub.nix
  - Files: `pkgs/double-minegrub-menu.nix`, `boot/minegrub.nix`.
  - Notes: only lacuna imports the theme.
  - Risk: hardware minegrub module, broken mainmenu path.
  - Detail: tasks/T29.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T30 [S30] (blocked-by: none): Enable PipeWire with ALSA and PulseAudio compatibility
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.pipewire.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.pipewire.pulse.enable | grep -qx true
  - Files: `roles/desktop/system/services.nix`.
  - Notes: 32-bit ALSA is enabled.
  - Risk: missing PulseAudio bridge.
  - Detail: tasks/T30.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T31 [S31] (blocked-by: none): Route DNS through systemd-resolved with Cloudflare DoT
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.services.resolved.extraConfig | grep -q "security.cloudflare-dns.com"
  - Files: `modules/services/network-services.nix`.
  - Notes: DNS-over-TLS is enforced.
  - Risk: plaintext fallback.
  - Detail: tasks/T31.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T32 [S32] (blocked-by: none): Configure NetworkManager with iwd and sops Wi-Fi profiles
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.config.networking.networkmanager.wifi.backend | grep -qx iwd && grep -q "wireless_env" hardware/wifi.nix
  - Files: `hardware/wifi.nix`.
  - Notes: profiles read `wireless_env`.
  - Risk: invalid key-mgmt, missing secret.
  - Detail: tasks/T32.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T33 [S33] (blocked-by: none): Enable udisks2, gvfs, and usbmuxd
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.udisks2.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.gvfs.enable | grep -qx true
  - Files: `roles/desktop/system/services.nix`.
  - Notes: desktop media and iOS access.
  - Risk: root-only mounts.
  - Detail: tasks/T33.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T34 [S34] (blocked-by: none): Keep thermald, upower, and power-profiles-daemon in the laptop profile
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.thermald.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.services.upower.enable | grep -qx true
  - Files: `profiles/laptop/default.nix`.
  - Notes: chassis policy only.
  - Risk: hardware traits owning policy.
  - Detail: tasks/T34.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T35 [S35] (blocked-by: none): Keep recursive module discovery in lib/default.nix
  - Verify: grep -q "mkModuleLoader" modules/default.nix && test -f lib/default.nix
  - Files: `lib/default.nix`, `modules/default.nix`.
  - Notes: new modules are discovered automatically.
  - Risk: manual import drift.
  - Detail: tasks/T35.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T36 [S36] (blocked-by: none): Keep the local package overlay recursive
  - Verify: nix eval --raw .#nixosConfigurations.lacuna.pkgs.double-minegrub-menu.name | grep -q double-minegrub-menu && grep -q "kebabToCamel" pkgs/default.nix
  - Files: `pkgs/default.nix`, `pkgs/`.
  - Notes: file names stay kebab, directory scopes camelCase.
  - Risk: missing package, broken scope.
  - Detail: tasks/T36.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T37 [S37] (blocked-by: none): Expose every language devShell and alias
  - Verify: for s in default ts c rust python pico nix typescript js clang cpp; do nix eval .#devShells.x86_64-linux.$s.name >/dev/null || exit 1; done
  - Files: `flake/devshells.nix`, `flake/default.nix`.
  - Notes: shells stay flake-local.
  - Risk: missing alias, stale package.
  - Detail: tasks/T37.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T38 [S38] (blocked-by: none): Trust the Termux, community, and Hyprland Cachix caches
  - Verify: nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "nix-on-droid.cachix.org" && nix eval --json .#nixosConfigurations.lacuna.config.nix.settings.substituters | grep -q "hyprland.cachix.org"
  - Files: `modules/system/cachix.nix`.
  - Notes: cache.nixos.org stays default.
  - Risk: missing public key.
  - Detail: tasks/T38.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T39 [S39] (blocked-by: T10): Keep server ingress ports with the Headscale role
  - Verify: grep -q "Headscale ingress" roles/server/system/default.nix && grep -q "allowedUDPPorts = \[ 3478 \]" roles/server/system/default.nix
  - Files: `roles/server/system/default.nix`.
  - Notes: ports 80/443 and 3478.
  - Risk: ports in generic modules.
  - Detail: tasks/T39.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T40 [S40] (blocked-by: none): Enable BTRFS scrub, zram, and explicit mount options
  - Verify: nix eval .#nixosConfigurations.lacuna.config.services.btrfs.autoScrub.enable | grep -qx true && nix eval .#nixosConfigurations.lacuna.config.zramSwap.enable | grep -qx true
  - Files: `hardware/filesystems.nix`.
  - Notes: monthly scrub and zram swap.
  - Risk: missing scrub, lost mount flags.
  - Detail: tasks/T40.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T41 [S41] (blocked-by: T14): Move flake checks into `tests/` and split them by domain
  - Verify: nix build .#checks.x86_64-linux.layout .#checks.x86_64-linux.policy .#checks.x86_64-linux.hardware .#checks.x86_64-linux.home .#checks.x86_64-linux.services .#checks.x86_64-linux.users
  - Files: `tests/default.nix`, `tests/{layout,policy,hardware,home,services,users}.nix`, `flake/default.nix`.
  - Notes: `tests/default.nix` recursively imports domain files; flake only imports the tests tree.
  - Risk: duplicate domain names, missing test file, stale path checks.
  - Detail: tasks/T41.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T42 [S42] (blocked-by: T17): Port zsh, zoxide, git, direnv, tealdeer, and core terminal tools into `home/modules/cli`
  - Verify: test -f home/modules/cli/zsh.nix && nix eval .#homeConfigurations.hollowheap.config.programs.zsh.enable | grep -qx true && nix eval .#homeConfigurations.hollowheap.config.programs.eza.enable | grep -qx true
  - Files: `home/modules/cli/{zsh,zoxide,tools,git,ssh,direnv,tealdeer}.nix`, `home/cli.nix`.
  - Notes: zsh-fzf-tab-source was dropped because the sibling module referenced an undefined `zshPlugins`.
  - Risk: duplicate options, custom package missing from nixpkgs.
  - Detail: tasks/T42.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T43 [S43] (blocked-by: T42): Port starship, tmux, and wallust-themed bat/btop/yazi/lazygit config after sharing style options with CLI
  - Verify: test -f home/modules/cli/starship.nix
  - Files: `home/modules/cli/starship.nix`, `home/modules/cli/tmux.nix`, `home/modules/cli/{bat,btop,yazi,lazygit}.nix`.
  - Notes: move `styles.pills` and wallust templates into the CLI tier or a shared base first.
  - Risk: GUI-only theme dependency, duplicate options.
  - Detail: tasks/T43.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T44 [S43] (blocked-by: T42): Port GUI app modules into opt-in `home/modules/apps/gui` bundles
  - Verify: test -f home/modules/apps/gui/ghostty.nix
  - Files: `home/modules/apps/gui/{ghostty,zen-browser,vesktop,thunderbird,obs-studio,pear-desktop}.nix`.
  - Notes: keep each app optional and absent from CLI-only hosts.
  - Risk: missing external flake modules, GUI leakage into CLI.
  - Detail: tasks/T44.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T45 [S43] (blocked-by: T42): Port opencode and the AI option schema into `home/modules/cli`
  - Verify: test -f home/modules/cli/opencode.nix && nix eval .#homeConfigurations.hollowheap.config.programs.opencode.enable | grep -qx true
  - Files: `home/modules/cli/{opencode,ai-options,ai-render,opencode-ai-hooks.ts}`, `home/cli.nix`.
  - Notes: AI agents/skills content and nvim/nvf remain separate slices.
  - Risk: HM opencode option drift, wallust template path.
  - Detail: tasks/T45.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

### Open

- [ ] T22 [S22] (blocked-by: T10): Add DuckDNS DNS-01 for publicly trusted Caddy certificates
  - Verify: grep -q "dns duckdns" roles/server/system/default.nix
  - Files: `roles/server/system/default.nix`, `flake.nix`, `secrets.yaml`.
  - Notes: only the public baseDomain vhost uses DNS-01; loopback Headscale/Vaultwarden still use internal TLS. Runtime issuance untested.
  - Risk: missing token, DuckDNS subdomain delegation, plugin hash mismatch.
  - Detail: tasks/T22.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [ ] T23 [S23] (blocked-by: T01): Make passwords and SSH keys declarative through sops
  - Verify: nix eval .#nixosConfigurations.lacuna.config.users.users.hollowheap.hashedPasswordFile >/dev/null
  - Files: `modules/system/users.nix`, `secrets.yaml`, `.sops.yaml`.
  - Notes: Deferred until hollowheap's password hash and SSH keys are supplied; steve remains a non-admin test user. Disable mutable users only after keys are declared.
  - Risk: account lockout, missing secret.
  - Detail: tasks/T23.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T46 [S43] (blocked-by: T42): Port auxiliary services and core environment modules
  - Verify: test -f home/modules/cli/services.nix
  - Files: `home/modules/cli/{services-auth-agents,rclone,store-hygiene,env,accounts,packages}.nix`.
  - Notes: keep GUI-only services out of CLI.
  - Risk: service assumptions, missing packages.
  - Detail: tasks/T46.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T47 [S43] (blocked-by: T42): Port default apps and remaining shell utilities
  - Verify: test -f home/modules/cli/default-apps.nix
  - Files: `home/modules/cli/{default-apps,utilities,fastfetch}.nix`.
  - Notes: mimeApps defaults, delta/wallust-free utilities, fastfetch.
  - Risk: references to missing GUI apps, duplicate options.
  - Detail: tasks/T47.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T76 [S43] (blocked-by: T45): Port nvim/nvf modules into `home/modules/cli`
  - Verify: test -f home/modules/cli/nvim.nix
  - Files: `home/modules/cli/nvim/*.nix`, `flake.nix`.
  - Notes: requires the nvf input and the wallust nvim template.
  - Risk: large closure, nvf option drift.
  - Detail: tasks/T76.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T77 [S43] (blocked-by: T45): Port AI agents, disciplines, rules, skills, and hooks content
  - Verify: test -f home/modules/cli/ai-agents.nix
  - Files: `home/modules/cli/ai/{agents,disciplines,rules,skills,hooks}.nix`.
  - Notes: fills the schema ported in T45 with the actual prompt/skill content.
  - Risk: prompt drift, missing skill assets.
  - Detail: tasks/T77.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T78 [S47] (blocked-by: none): Extract Neovim quickfix, preview, and editing domain modules
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/programs/nvim/{quickfix,preview,editing,debugger,core,keymaps}.nix`, `home/modules/programs/nvim.nix`.
  - Notes: Co-locate lazy plugin definitions, whichKey registrations, and keymaps; remove them from `core.nix` and `keymaps.nix`.
  - Risk: keybinding conflicts or syntax errors in nvf Lua configurations.
  - Detail: tasks/T78.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T79 [S48] (blocked-by: none): Encode universal harness clamps and partition eager/lazy skills
  - Verify: nix build .#checks.x86_64-linux.home && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/ai/rules.nix`, `home/modules/ai/agents.nix`, `.artifacts/DECISIONS.md`.
  - Notes: Generalize empirical retro failure modes into framework-agnostic clamps (runner check, exact verify, gate integrity, experiment timebox, subagent caps); prune 7 domain skills from primary `engineer` agent to slim eager prompt footprint.
  - Risk: capability mismatch or broken subagent skill availability.
  - Detail: tasks/T79.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T80 [S49] (blocked-by: none): Consolidate frontend micro-skills into ui-author and ui-audit umbrella skills
  - Verify: test -f assets/skills/review/references/ui.md
  - Files: `home/modules/ai/skills.nix`, `home/modules/ai/agents.nix`, `.artifacts/DECISIONS.md`.
  - Notes: Superseded by review absorption; UI authoring and audit guidance now lives in `assets/skills/review/references/ui.md`.
  - Risk: missing references or broken schema generation.
  - Detail: tasks/T80.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T81 [S50] (blocked-by: none): Author and wire backend-author and modular-design umbrella skills
  - Verify: test -f assets/skills/review/references/backend.md && test -f assets/skills/modular-design/SKILL.md
  - Files: `home/modules/ai/skills.nix`, `home/modules/ai/agents.nix`, `.artifacts/DECISIONS.md`, `.artifacts/SPECS.md`.
  - Notes: Superseded by review absorption; backend guidance now lives in `assets/skills/review/references/backend.md`, while `modular-design` remains a standalone skill.
  - Risk: missing reference patterns or broken schema generation.
  - Detail: tasks/T81.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T82 [S51] (blocked-by: none): Align harness model routing and reasoning effort
  - Verify: nix build .#checks.x86_64-linux.home && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/programs/codex.nix`, `home/modules/programs/kiro-cli.nix`, `home/modules/ai/options.nix`, `.artifacts/DECISIONS.md`, `.artifacts/SPECS.md`.
  - Notes: Codify `gpt-6-luna` (xhigh) for Codex settings and agent profiles; map Kiro agents to `claude-sonnet-5.5` (low) for high tier and `claude-haiku-5.5` (xhigh) for medium/low tiers; switch global `ai.tiers` default to `opencode-go`.
  - Risk: invalid JSON/TOML keys or broken Home Manager generation.
  - Detail: tasks/T82.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T83 [S52] (blocked-by: none): Declarative dynamic Bitwarden/rbw key delivery for AI harnesses
  - Verify: home-manager switch --flake .#hollowheap
  - Files: `home/modules/terminal/zsh.nix`, `home/modules/programs/opencode.nix`, `home/modules/programs/pi-coding-agent.nix`, `home/modules/ai/hooks.nix`.
  - Notes: Zsh automatically exports `OPENCODE_API_KEY` on shell startup and dynamically in a `preexec` hook before AI harness commands; OpenCode config explicitly searches for `OPENCODE_API_KEY`; Pi natively resolves keys using dynamic `!rbw get` execution via declarative `auth.json`; `ai-hooks.nix` guards session-start against non-git scans with a 5s timeout.
  - Risk: locked vault at invocation, clobbered auth files on activation.
  - Detail: tasks/T83.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T84 [S53] (blocked-by: none): Declare XDG user directories and unify Wallust template directory
  - Verify: home-manager switch --flake .#hollowheap
  - Files: `home/modules/environment/session.nix`, `home/modules/programs/wallust.nix`, `home/modules/programs/noctalia.nix`.
  - Notes: `xdg.userDirs` declares standard directories while redirecting templates, desktop, and publicShare into `~/.local/share/`; Wallust templates deploy into `${config.xdg.userDirs.templates}` and mirror to `~/.config/wallust/templates`; Noctalia invokes Wallust with `--templates-dir`.
  - Risk: missing directories or broken template path.
  - Detail: tasks/T84.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T85 [S54] (blocked-by: none): Decompose server system role into vertical slices
  - Verify: nix build .#checks.x86_64-linux.services && nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run
  - Files: `roles/server/system/{default,caddy,headscale,vaultwarden,ddclient,domains}.nix`, `tests/services.nix`.
  - Notes: Extract `caddy.nix`, `headscale.nix`, `vaultwarden.nix`, `ddclient.nix`, and `domains.nix`; update `roles/server/system/default.nix` to aggregate; update `tests/services.nix` assertions.
  - Risk: broken reverse proxy configuration, unmerged vhosts, failed NixOS dry-run.
  - Detail: tasks/T85.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T86 [S55] (blocked-by: T85): Reorganize home modules into terminal, cli, and programs taxonomy
  - Verify: nix build .#checks.x86_64-linux.home && nix build .#checks.x86_64-linux.layout && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/{terminal,cli,programs}/`, `tests/home.nix`, `AGENTS.md`.
  - Notes: Move shell & multiplexers into `terminal/`, standalone utilities into `cli/`, keep GUI apps & harnesses in `programs/`; update `tests/home.nix` and `AGENTS.md`.
  - Risk: path mismatch in tests, broken imports, missing symlinks.
  - Detail: tasks/T86.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T87 [S56] (blocked-by: none): Author OMP harness module and wire flake inputs and ai.* abstractions
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `flake.nix`, `flake/default.nix`, `home/modules/programs/omp.nix`, `home/modules/ai/options.nix`, `home/modules/ai/hooks.nix`.
  - Notes: Add `inputs.omp` pointing to `github:can1357/oh-my-pi`; import `inputs.omp.homeManagerModules.default` in `flake/default.nix`; create `home/modules/programs/omp.nix` deploying skills, agents, disciplines, rules, and hooks into `~/.omp/agent/`; update `home/modules/ai/hooks.nix` and `home/modules/ai/options.nix`.
  - Risk: flake lock resolution time, bun/rust dependency mismatches.
  - Detail: tasks/T87.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T88 [S57] (blocked-by: none): Configure Pi settings to exclude tool-search, mcp, and llama.cpp built-ins
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.pi-coding-agent.settings.extensions && nix build .#checks.x86_64-linux.home
  - Files: `home/modules/programs/pi-coding-agent.nix`, `tests/home.nix`.
  - Notes: Add `extensions = [ "-builtin:tool-search" "-builtin:mcp" "-builtin:llama.cpp" ];` to `programs.pi-coding-agent.settings` and verify via HM eval and domain checks.
  - Risk: none.
  - Detail: tasks/T88.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T89 [S58] (blocked-by: none): Wire Noctalia wallpaper hook directly to Wallust and icon/GTK accent dispatchers
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.noctalia.settings.theme.templates.builtin_ids | grep -q '"hyprland"' && grep -q wallust "$(nix eval --raw .#homeConfigurations.hollowheap.config.programs.noctalia.settings.hooks.wallpaper_changed)" && nix build .#checks.x86_64-linux.home
  - Files: `home/modules/programs/noctalia.nix`, `home/modules/programs/wallust.nix`, `home/modules/programs/hyprland/hyprland.nix`, `pkgs/mactahoe-icon-accent.py`, `pkgs/mactahoe-icon-accent.nix`.
  - Notes: Replace Noctalia stub user templates with direct wallpaper_changed hook execution of Wallust, GTK accent, icon accent, and OpenRGB; use Noctalia builtin `hyprland` template for Hyprland colors; update mactahoe-icon-accent to sync dconf, gsettings, and GTK settings.ini.
  - Risk: none.
  - Detail: tasks/T89.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T90 [S59] (blocked-by: none): Integrate diagram.nvim and image.nvim with CLI renderers in Neovim
  - Verify: nix eval --raw '.#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.lazy.plugins."diagram.nvim".setupModule' | grep -q "diagram" && nix build .#checks.x86_64-linux.home
  - Files: `home/modules/programs/nvim/diagrams.nix`, `home/modules/programs/nvim.nix`, `flake/default.nix`, `tests/home.nix`.
  - Notes: Add `"diagram.nvim"` to `allowUnfreePredicate`; author `home/modules/programs/nvim/diagrams.nix` configuring `image.nvim` (kitty protocol, eager start plugin), `diagram.nvim` (lazy plugin, markdown/neorg integrations), CLI tools (`imagemagick`, `mermaid-cli`, `plantuml`, `d2`, `graphviz`), and `<leader>m` bindings; import in `nvim.nix`; update `tests/home.nix`.
  - Risk: none.
  - Detail: tasks/T90.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T91 [S60] (blocked-by: none): Author on-demand retro skill in home/modules/ai/skills.nix
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.retro.description | grep -q "retrospective" && test -f home/modules/ai/skills.nix
  - Files: `home/modules/ai/skills.nix`, `.artifacts/RETRO.md`.
  - Notes: Define `retro` skill with 5-step workflow inspecting active `transcript.jsonl`, quantifying metrics, checking rule compliance, and emitting to `.artifacts/RETRO.md`.
  - Risk: none.
  - Detail: tasks/T91.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T92 [S61] (blocked-by: none): Author corpus-audit skill in home/modules/ai/skills.nix
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.skills.corpus-audit.description | grep -q "corpus-audit" && test -f home/modules/ai/skills.nix
  - Files: `home/modules/ai/skills.nix`.
  - Notes: Define `corpus-audit` skill ingesting multi-session logs across past runs and SQLite logs, auditing workspace blind spots, cognitive traps, and tool waste into `.artifacts/audit.md`.
  - Risk: none.
  - Detail: tasks/T92.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T93 [S62]: Render every harness from the shared agent body
  - Verify: nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".omp/agent/agents/engineer.md"'.text | grep -q 'Read target slices' && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/programs/{pi-coding-agent,omp,codex,kiro-cli,antigravity,github-copilot-cli,crush}.nix`.
  - Notes: Replace `agent.instructions` interpolation with `config.ai.render.agentBodyFor`; keep harness-specific wrappers.
  - Risk: duplicate discipline blocks, empty body, renderer option mismatch.
  - Detail: tasks/T93.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T94 [S62] [T93]: Resolve model and effort through per-harness tier adapters
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.opencode.agents.engineer | grep -q 'opencode-go' && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/ai/options.nix`, `home/modules/programs/{opencode,pi-coding-agent,omp,codex,kiro-cli,antigravity,github-copilot-cli,crush}.nix`.
  - Notes: Add `modelFor` and `effortFor` branches for every harness; preserve `models.<harness>` overrides; remove hardcoded model tables.
  - Risk: provider/model IDs diverge, effort vocabulary mismatch, invalid generated TOML/JSON.
  - Detail: tasks/T94.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T95 [S63]: Add one MCP stdio registry and render it across supporting harnesses
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.programs.mcp.servers && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/ai/options.nix`, `home/modules/programs/{opencode,codex,crush,github-copilot-cli}.nix`.
  - Notes: Define `programs.mcp.servers` with command, args, env, and enabled; gate access through `capabilities.mcp`; render the same enabled set in each supporting harness. No default server is installed; the registry is empty until configured.
  - Risk: differing server schemas, capability bypass, remote transport accidentally accepted.
  - Detail: tasks/T95.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T96 [S64]: Route all harness hooks through `ai.hooks` and fail closed
  - Verify: nix eval --json .#homeConfigurations.hollowheap.config.ai.hooks && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/ai/hooks.nix`, `home/modules/ai/options.nix`, `home/modules/programs/{opencode,pi-coding-agent,omp,codex,kiro-cli,antigravity,github-copilot-cli,crush,hermes}.nix`.
  - Notes: Preserve event, command, args, matcher, timeout, enabled, and harness filters; remove dead hook files; make malformed pre-tool payloads exit nonzero. Pi and OMP have no native hook surface, so their dead hook files were removed rather than retained.
  - Risk: fail-open regression, matcher mismatch, harness-specific event loss.
  - Detail: tasks/T96.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T97 [S65]: Fix OpenCode permission ordering and remove the invalid `write` key
  - Verify: nix eval --raw .#homeConfigurations.hollowheap.config.programs.opencode.agents.architect | grep -q 'permission:' && ! nix eval --raw .#homeConfigurations.hollowheap.config.programs.opencode.agents.architect | sed -n '/^permission:/,/^---/p' | grep -q '^  write:' && nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/programs/opencode.nix`.
  - Notes: Emit deny-all before specific allows; derive task allows from `availableAgents`; keep architect artifact edits and scout delegation.
  - Risk: deny-last ordering, invalid permission key, denied delegation.
  - Detail: tasks/T97.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T98 [S65] [T97]: Map capability flags to native tool lists for non-OpenCode harnesses
  - Verify: nix build .#homeConfigurations.hollowheap.activationPackage --no-link
  - Files: `home/modules/programs/{codex,kiro-cli,antigravity,github-copilot-cli,crush}.nix`, `home/modules/ai/options.nix`.
  - Notes: Remove tools not declared by `capabilities.read`, `write`, `execute`, `delegate`, `mcp`, or `web`; keep harness-native tool names.
  - Risk: over-restricting a harness, tool-name drift, hidden delegation.
  - Detail: tasks/T98.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T99 [S70]: Drop shared model and effort routing abstractions
  - Verify: `! rg -q 'modelFor|effortFor|ai\.tiers|harness-routing' home/modules home/lib --glob '*.nix' && nix build .#homeConfigurations.hollowheap.activationPackage --no-link`
  - Files: `home/modules/ai/options.nix`, `home/lib/ai-render.nix`, `home/modules/ai/harness-routing.nix`, `home/modules/ai/harnesses.nix`, `home/modules/programs/*.nix`, `tests/home.nix`.
  - Notes: set model and effort literals in each adapter and remove shared tier helpers.
  - Risk: missing adapter-local model, stale test assertion, eval failure from removed option.
  - Detail: tasks/T99.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T100 [S68] [T99]: Enable Codex with a prebuilt package
  - Verify: `nix eval .#homeConfigurations.hollowheap.config.programs.codex.enable | grep -qx true && ! rg -q 'AWS_LC_SYS_USE_SYSTEM' home/modules/programs/codex.nix && nix build .#homeConfigurations.hollowheap.activationPackage --no-link`
  - Files: `home/modules/programs/codex.nix`, `tests/home.nix`.
  - Notes: enable the adapter and source a cached or upstream binary without local native compilation.
  - Risk: disabled adapter, vendored build during activation, missing agent or hook files.
  - Detail: tasks/T100.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T101 [S69] [T99]: Remove Kiro subagent capability stripping
  - Verify: `! rg -q 'subagentOnly' home/modules/programs/kiro-cli.nix && nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".kiro/agents/worker.json"'.text | jq -e '.tools | index("web")'`
  - Files: `home/modules/programs/kiro-cli.nix`, `tests/home.nix`.
  - Notes: render shared capabilities for subagent roles without harness-local pruning.
  - Risk: stripped tools, capability drift, broken JSON agent files.
  - Detail: tasks/T101.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T102 [S67]: Render MCP servers from one shared registry into every capable harness
  - Verify: `nix eval --json .#homeConfigurations.hollowheap.config.programs.mcp.servers | jq -e '.refero.exposure == "codemode"' && ! rg -q 'mcpServers' home/modules/programs/pi-coding-agent.nix`
  - Files: `home/modules/ai/options.nix`, `home/lib/ai-render.nix`, `home/modules/programs/*.nix`, `tests/home.nix`.
  - Notes: replace Pi's private registry with the shared registry and keep codemode exposure.
  - Risk: private registry survives, direct exposure, server missing from an adapter.
  - Detail: tasks/T102.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T103 [S66]: Adapt hook contracts to harness builtins
  - Verify: `nix build .#checks.x86_64-linux.home --no-link && nix eval --json .#homeConfigurations.hollowheap.config.ai.hooks --apply 'h: builtins.hasAttr "pre-tool" h' | grep -qx true`
  - Files: `home/modules/ai/hooks.nix`, `home/lib/ai-render.nix`, `home/modules/programs/*.nix`, `tests/home.nix`.
  - Notes: add per-harness drops for hooks already provided natively while preserving one shared command, matcher, and timeout shape.
  - Risk: duplicate external hook, dropped hook without builtin, fail-open pre-tool execution.
  - Detail: tasks/T103.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T104 [S71]: Remove repomap hook, generator, and artifacts
  - Verify: `! rg -q 'repomap' home/modules/ai/hooks.nix && test ! -f pkgs/repomap.nix && test ! -e .artifacts/repomap.md && ! rg -q 'repomap' .artifacts/ARCHITECTURE.md`
  - Files: `home/modules/ai/hooks.nix`, `pkgs/repomap.nix`, `.artifacts/REPOMAP.md`, `home/modules/programs/kiro-cli.nix`, `.artifacts/ARCHITECTURE.md`, `tests/home.nix`.
  - Notes: delete the hook entries, generator package, Kiro resource, and lowercase artifact.
  - Risk: surviving lowercase map, stale Kiro resource, documentation drift.
  - Detail: tasks/T104.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [ ] T108 [S72]: Shared secrets decrypt on both hosts while server-only secrets stay restricted
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.sops.secrets --apply 's: s ? vaultwarden_env && s ? wireless_env' | grep -qx true && nix eval --json .#nixosConfigurations.acervus.config.sops.secrets --apply 's: !(s ? vaultwarden_env) && s ? wireless_env' | grep -qx true`
  - Files: `secrets/secrets.yaml, modules/security/sops.nix, hosts/lacuna/default.nix, hosts/acervus/default.nix, .sops.yaml`.
  - Notes: Host secret scope matches host duty; a non-server cannot decrypt server credentials..
  - Risk: One encrypted blob shared by both hosts, missing recipient, leaked server secret..
  - Detail: tasks/T108.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T109 [S73]: Host-specific display, Wacom, and Yoga values stay outside shared desktop options
  - Verify: `test -d home/hosts && nix eval --raw .#homeConfigurations.hollowheap.config.desktop.touchscreen.switchDevice >/dev/null && nix eval --json .#homeConfigurations.hollowheap.config.desktop.monitors | jq -e 'length > 0'`
  - Files: `modules/options/desktop.nix, home/hollowheap.nix, home/hosts/lacuna.nix, hosts/lacuna/default.nix`.
  - Notes: Shared desktop defaults stay neutral while lacuna supplies concrete hardware values..
  - Risk: Laptop literals in shared defaults, absent host overlay, compositor drift..
  - Detail: tasks/T109.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T110 [S74]: Checks, license policy, and shared helpers are exposed through stable flake seams
  - Verify: `nix eval --raw .#lib >/dev/null && nix eval --json .#homeConfigurations.hollowheap.config.unfreePackages --apply 'ps: builtins.isList ps' | grep -qx true && test -f tests/default.nix`
  - Files: `flake/default.nix, tests/default.nix, modules/system/nixpkgs.nix, home/modules/core/unfree.nix`.
  - Notes: A new domain check or unfree package registers without editing the composition root..
  - Risk: Inline checks shadow tests/, hardcoded license list, missing outputs.lib..
  - Detail: tasks/T110.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [ ] T111 [S75]: The shell receives EOF on Ctrl-D while the popup stays behind the prefix
  - Verify: `rg -q '^bind d ' home/modules/terminal/tmux.nix && ! rg -q '^bind -n C-d' home/modules/terminal/tmux.nix && ! rg -q "'^D'" home/modules/terminal/zsh.nix`
  - Files: `home/modules/terminal/tmux.nix, home/modules/terminal/zsh.nix`.
  - Notes: Ctrl-D ends input in a shell or REPL; prefix-d opens the container popup..
  - Risk: Root binding steals EOF, zsh unbinds Ctrl-D, documented prefixes regress..
  - Detail: tasks/T111.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [ ] T112 [S76]: Agent capabilities and artifact paths are enforced consistently across harnesses
  - Verify: `nix eval --raw .#homeConfigurations.hollowheap --apply 'h: h.config.ai.render.agentBodyFor h.config.ai.agents.worker' | rg -q 'Task executor' && ! rg -q 'subagent-io' home/modules/ai/agents.nix && rg -q '\.artifacts/\*\.md' home/modules/programs/kiro-cli.nix`
  - Files: `home/modules/ai/options.nix, home/modules/ai/agents.nix, home/modules/programs/kiro-cli.nix, lib/ai-skills.nix`.
  - Notes: Write-capable agents avoid read-only mandates; canonical artifact globs and parsed skills hold..
  - Risk: Contradictory discipline, lowercase artifact paths, malformed skill YAML, fail-open hooks..
  - Detail: tasks/T112.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T113 [S77]: Every discovered host and user is covered by evaluated checks
  - Verify: `nix eval --json .#nixosConfigurations --apply 'c: builtins.length (builtins.attrNames c)' | grep -qx 2 && nix eval --json .#checks.x86_64-linux --apply 'c: builtins.hasAttr "ai-rendered" c && builtins.hasAttr "skills-rendered" c' | grep -qx true && nix flake check --no-build >/dev/null`
  - Files: `flake/default.nix, tests/default.nix, tests/layout.nix, tests/home.nix`.
  - Notes: Adding a host or user adds corresponding checks; no inline derivation shadows tests/..
  - Risk: Unchecked discovered output, inline check collision, untracked test silently dropped..
  - Detail: tasks/T113.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T114 [S78]: HDR is available on the hardware that supports it and absent elsewhere
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.desktop.hdr | jq -e '. == true' && nix eval --json .#nixosConfigurations.acervus.config.desktop.hdr | jq -e '. == false' && nix eval --json .#homeConfigurations.hollowheap.config.desktop.hdr | jq -e '. == true'`
  - Files: `hardware/hdr.nix, hosts/lacuna/hardware.nix, home/hollowheap.nix, home/modules/programs/hyprland/hyprland.nix`.
  - Notes: Lacuna compositor enables HDR; acervus and headless contexts stay SDR..
  - Risk: Orphan trait setter, HDR on unsupported hardware, cross-layer disagreement..
  - Detail: tasks/T114.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T115 [S79]: Laptop geometry is supplied by host data, not shared defaults
  - Verify: `nix eval --json .#nixosConfigurations.acervus.config.desktop.primaryOutput | jq -e '. == null' && nix eval --raw .#nixosConfigurations.lacuna.config.desktop.primaryOutput | grep -qx eDP-1`
  - Files: `modules/options/desktop.nix, hosts/lacuna/default.nix, home/hosts/lacuna.nix`.
  - Notes: Headless hosts carry no phantom panel layout; compositor values come from lacuna data..
  - Risk: Laptop defaults leak to acervus, HM overlay missing, monitor list empty..
  - Detail: tasks/T115.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T116 [S80]: Login and desktop sessions consume the same output, layout, input, and font policy
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.output | jq -e 'has("name")' && nix eval --json .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.keyboard | jq -e 'has("variant") and has("options")' && nix eval --raw .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.appearance.font_family | grep -q .`
  - Files: `roles/desktop/system/default.nix, modules/options/desktop.nix, home/modules/programs/hyprland/hyprland.nix`.
  - Notes: Changing shared desktop data changes both login and compositor surfaces..
  - Risk: Greeter pins eDP-1, drops XKB variant/options, or omits font family..
  - Detail: tasks/T116.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T117 [S81]: Desktop shell touch and compositor touch are separate host-scoped policies
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.desktop.touch | grep -qx true && nix eval --json .#homeConfigurations.hollowheap.config.desktop.touch | grep -qx true && rg -q 'config.desktop.touch' home/modules/programs/hyprland/hyprland.nix`
  - Files: `hardware/touch.nix, home/hollowheap.nix, home/hosts/lacuna.nix, home/modules/environment/touch.nix, home/modules/programs/hyprland/hyprland.nix`.
  - Notes: Each layer owns its touch integration; no orphan NixOS setter or unconditional HM flag..
  - Risk: Duplicate boolean, version throw on non-touch host, shell/compositor disagreement..
  - Detail: tasks/T117.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T118 [S82]: Stay-awake behavior owns lid-close policy; stale suspend assertions are gone
  - Verify: `! rg -q 'HandleLidSwitch' profiles/laptop/default.nix tests/policy.nix && rg -q 'caffeine' home/modules/programs/noctalia.nix`
  - Files: `profiles/laptop/default.nix, tests/policy.nix, home/modules/programs/noctalia.nix`.
  - Notes: Active stay-awake prevents suspend; no split logind policy remains..
  - Risk: Stale suspend assertion, inhibitor coordination hidden in NixOS layer..
  - Detail: tasks/T118.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T119 [S83]: Power saving lowers the actual configured refresh rate
  - Verify: `nix eval --raw .#homeConfigurations.hollowheap.config.home.file.'".config/hypr/scripts/power-mode.sh"'.text | rg -q '@60' && ! rg -q 'replaceStrings' home/modules/services/power-mode.nix`
  - Files: `home/modules/services/power-mode.nix, modules/options/desktop.nix`.
  - Notes: A 120 Hz monitor drops to 60 Hz in power-saver without literal substitution..
  - Risk: Non-120 modes stay fast, per-monitor scale discarded..
  - Detail: tasks/T119.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T120 [S84]: Login screen uses the installed shared font families
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.fonts.packages | jq -e 'length > 0' && nix eval --raw .#nixosConfigurations.lacuna.config.services.displayManager.noctalia-greeter.settings.appearance.font_family | grep -q .`
  - Files: `roles/desktop/system/default.nix, modules/options/desktop.nix`.
  - Notes: Sans, serif, and monospace packages are installed for the greeter..
  - Risk: Generic fallback font, HM-only font installation..
  - Detail: tasks/T120.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T121 [S85]: Compositor geometry no longer exposes an unused bar-height option
  - Verify: `! rg -q 'barHeight' home/modules/environment/compositor.nix home/modules/programs/hyprland home/modules/programs/noctalia.nix`
  - Files: `home/modules/environment/compositor.nix, home/modules/programs/noctalia.nix`.
  - Notes: Setting or removing bar height has no dead option surface..
  - Risk: Dead option advertised, panel geometry split across modules..
  - Detail: tasks/T121.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T122 [S86]: Portal ownership stays system-level with the Hyprland portal selected
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.xdg.portal.enable | jq -e '. == true' && nix eval --json .#nixosConfigurations.lacuna.config.xdg.portal.extraPortals | jq -e 'length > 0'`
  - Files: `roles/desktop/system/default.nix, home/modules/environment/rules.nix`.
  - Notes: Screen-share and file-picker rules match the installed portal..
  - Risk: Portal config in user scope, portal app id mismatch..
  - Detail: tasks/T122.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T123 [S87]: Every declared theme template has a matching asset and a checked consumer
  - Verify: `nix build .#checks.x86_64-linux.home --no-link >/dev/null && rg -q 'starship-palette.toml' tests/home.nix`
  - Files: `tests/home.nix, home/modules/programs/wallust.nix, assets/wallust-templates`.
  - Notes: Removing or renaming a declared template fails a check..
  - Risk: Hand-maintained asset list omits a template, stale theme target..
  - Detail: tasks/T123.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T124 [S88]: Wacom and Yoga switch names are host-scoped options
  - Verify: `nix eval --raw .#homeConfigurations.hollowheap.config.desktop.touchscreen.switchDevice | grep -q . && ! rg -q 'wacom-hid-53b7' home/modules/environment/touch.nix home/modules/programs/hyprland/keybinds.nix`
  - Files: `home/modules/environment/touch.nix, home/modules/programs/hyprland/keybinds.nix, home/hosts/lacuna.nix`.
  - Notes: Non-Yoga hosts do not receive vendor-specific device bindings..
  - Risk: Vendor literals in shared modules, missing host override..
  - Detail: tasks/T124.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T125 [S89]: Markdown saves do not run a formatter outside the unified toolchain
  - Verify: `nix eval --json .#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.formatter.conform-nvim.setupOpts.formatters_by_ft | jq -e 'has("markdown") | not'`
  - Files: `home/modules/core/toolchain.nix, home/modules/programs/nvim/lsp.nix`.
  - Notes: Prose and bullets are preserved on save while other filetypes keep their formatters..
  - Risk: deno fmt reflows Markdown, unified no-formatter contract inert..
  - Detail: tasks/T125.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T126 [S90]: Neovim no longer advertises or restores sessions
  - Verify: `! rg -q 'Restore Session|section = "session"' home/modules/programs/nvim/snacks.nix && ! rg -q 'mini.sessions' home/modules/programs/nvim/mini.nix`
  - Files: `home/modules/programs/nvim/snacks.nix, home/modules/programs/nvim/mini.nix`.
  - Notes: Dashboard and keymaps contain no session-restore entry..
  - Risk: Dead restore UI, autoread surprise on launch..
  - Detail: tasks/T126.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T127 [S91]: Agent keymaps remain present despite headless maparg limitations
  - Verify: `rg -q '"<leader>ar"' home/modules/programs/nvim/keymaps.nix && rg -q 'AvanteAsk|AvanteToggle|AvanteFocus' home/modules/programs/nvim/keymaps.nix`
  - Files: `home/modules/programs/nvim/keymaps.nix`.
  - Notes: The documented leader-a commands remain bound in a real session..
  - Risk: Headless probe deletes working bindings or which-key descriptions drift..
  - Detail: tasks/T127.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T128 [S92]: ACP providers use Nix-resolved paths instead of machine-local checkout literals
  - Verify: `! rg -q '/home/hollowheap/repos' home/modules/programs/nvim/completion.nix && rg -q 'acp_providers' home/modules/programs/nvim/completion.nix`
  - Files: `home/modules/programs/nvim/completion.nix, pkgs/default.nix`.
  - Notes: Provider paths resolve from Nix on every host..
  - Risk: Hardcoded home path, provider fails after checkout moves..
  - Detail: tasks/T128.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T129 [S93]: Shell scripts format with the unified formatter
  - Verify: `nix eval --json .#homeConfigurations.hollowheap.config.programs.nvf.settings.vim.formatter.conform-nvim.setupOpts.formatters_by_ft | jq -e '.bash == ["shfmt"] and .zsh == ["shfmt"]'`
  - Files: `home/modules/core/toolchain.nix, home/modules/programs/nvim/lsp.nix`.
  - Notes: Format-on-save works for bash and zsh buffers..
  - Risk: Only sh key registered, shfmt installed but unused..
  - Detail: tasks/T129.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T130 [S94]: Compositor start re-applies the persisted wallpaper theme
  - Verify: `rg -q 'settings.toml' home/modules/programs/noctalia.nix && rg -q 'wallpaper.last' home/modules/programs/noctalia.nix`
  - Files: `home/modules/programs/noctalia.nix`.
  - Notes: Restarting the shell restores GTK, icon, and Wallust state without a wallpaper change..
  - Risk: Started hook gated on a change-only environment variable..
  - Detail: tasks/T130.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T131 [S95]: Syntax roles keep distinguishable generated colors
  - Verify: `rg -q -F "base08 = '{{color9}}'" assets/wallust-templates/nvim-colors.lua && rg -q -F "base09 = '{{color11}}'" assets/wallust-templates/nvim-colors.lua && rg -q -F "base0A = '{{color3}}'" assets/wallust-templates/nvim-colors.lua && rg -q -F "base0F = '{{color5}}'" assets/wallust-templates/nvim-colors.lua`
  - Files: `assets/wallust-templates/nvim-colors.lua, home/modules/programs/nvim/ui.nix`.
  - Notes: Errors, constants, keywords, and deprecated tags remain visually separable..
  - Risk: Four roles collapse into two bright slots..
  - Detail: tasks/T131.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T132 [S96]: Editor checks assert evaluated behavior rather than file presence
  - Verify: `rg -q 'programs.nvf.settings' tests/home.nix && rg -q 'maparg|list_formatters|formatters_by_ft' tests/home.nix`
  - Files: `tests/home.nix`.
  - Notes: A regression in formatter maps or keymap binding fails a check..
  - Risk: String-only checks pass while editor behavior is broken..
  - Detail: tasks/T132.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T133 [S97]: Dead wallust pill helper is removed
  - Verify: `! rg -q 'pill_load_wallust' home/modules/styles/pills.nix`
  - Files: `home/modules/styles/pills.nix`.
  - Notes: No uncalled helper claims EOF-safe palette parsing..
  - Risk: Dead 108-line bash helper persists as misleading contract..
  - Detail: tasks/T133.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T134 [S98]: Dynamic colorschemes remain the only palette authority
  - Verify: `! test -e home/modules/styles/palette.nix && rg -q 'wallust' home/modules/programs/wallust.nix && rg -q 'theme' home/modules/programs/noctalia.nix`
  - Files: `home/modules/programs/wallust.nix, home/modules/programs/noctalia.nix, home/modules/styles`.
  - Notes: New colors come from wallpaper-derived schemes and no static ramp is planned..
  - Risk: Static palette module resurrected, two color authorities drift..
  - Detail: tasks/T134.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T135 [S99]: Every supported ACP provider is registered in the editor
  - Verify: `rg -q 'pi =' home/modules/programs/nvim/completion.nix && rg -q 'claude' home/modules/programs/nvim/completion.nix && rg -q 'agy' home/modules/programs/nvim/completion.nix && rg -q 'opencode' home/modules/programs/nvim/completion.nix`
  - Files: `home/modules/programs/nvim/completion.nix, docs/avante provider list`.
  - Notes: The named harnesses appear as selectable ACP providers..
  - Risk: Only Pi registered, provider list incomplete..
  - Detail: tasks/T135.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T136 [S100]: HTTPS ingress remains unchanged while the routing decision is open
  - Verify: `rg -q 'tls internal' roles/server/system/headscale.nix roles/server/system/vaultwarden.nix && ! rg -q 'tailscale cert' roles/server/system flake`
  - Files: `roles/server/system/caddy.nix, roles/server/system/headscale.nix, roles/server/system/vaultwarden.nix, roles/server/system/default.nix`.
  - Notes: No WAN exposure or Tailscale certificate dependency is introduced by this pass..
  - Risk: Premature ingress rewrite, untrusted client CA, WAN port opening..
  - Detail: tasks/T136.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [ ] T137 [S101]: Acervus installation is available as a squashfs image
  - Verify: `nix eval --raw '.#apps.x86_64-linux.install-acervus.program' >/dev/null && nix build .#images.acervus --dry-run >/dev/null`
  - Files: `flake/default.nix, hosts/acervus/*, pkgs/install-host.nix, nix-on-droid.nix`.
  - Notes: A fresh installer image can run disko and install the host without a prebuilt machine..
  - Risk: Installer exists only as a script, no reproducible image output..
  - Detail: tasks/T137.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T138 [S102]: Declarative identity uses the GPG auth subkey public credential
  - Verify: `nix eval --json .#nixosConfigurations.lacuna.config.users.mutableUsers | jq -e '. == false' && nix eval --json .#nixosConfigurations.lacuna.config.users.users.hollowheap.openssh.authorizedKeys.keys | jq -e 'any(.[]; startswith("ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmWse"))'`
  - Files: `modules/system/users.nix`.
  - Notes: The host accepts the GPG-derived SSH key and rejects imperative user drift..
  - Risk: Wrong key, mutable users, lockout after rebuild..
  - Detail: tasks/T138.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [ ] T139 [S103]: Remote mount browsing is tuned without changing mount mode
  - Verify: `nix eval --raw .#homeConfigurations.hollowheap.config.systemd.user.services.rclone-mount-gdrive.Service.ExecStart | jq -r '.[0]' | rg -q 'dir-cache-time 24h --vfs-cache-poll-interval 5m --vfs-fast-fingerprint'`
  - Files: `home/modules/services/rclone.nix`.
  - Notes: Directory listings stay fast while the remote remains mounted..
  - Risk: Switching to sync loses live mount, cache tuning removed..
  - Detail: tasks/T139.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T140 [S104]: Handheld HTTPS access stays unchanged until the server moves
  - Verify: `rg -q 'tls internal' roles/server/system/headscale.nix && rg -q 'SSL_CERT_FILE' roles/server/system/default.nix && nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion | grep -qx 24.05`
  - Files: `roles/server/system/default.nix, roles/server/system/headscale.nix, nix-on-droid.nix`.
  - Notes: No temporary mesh-pin or WAN forwarding workaround is introduced..
  - Risk: Fovea TLS changed before acervus exists, DNS pinned to wrong host..
  - Detail: tasks/T140.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [ ] T141 [S105]: Installer secrets use throwaway credentials that never enter git or the target
  - Verify: `! rg -q -i 'PRIVATE KEY' flake.nix pkgs/install-host.nix && rg -q 'ephemeral|throwaway|age' pkgs/install-host.nix`
  - Files: `flake/default.nix, pkgs/install-host.nix, hosts/acervus/*`.
  - Notes: A rebuilt ISO can install without committing or persisting the operator private key..
  - Risk: Private key committed, ISO bakes long-lived secret, target retains installer key..
  - Detail: tasks/T141.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

### References
- Requirements: [.artifacts/REQUIREMENTS.md](file:///home/hollowheap/repos/nixos-config/.artifacts/REQUIREMENTS.md)
- Decisions: [.artifacts/DECISIONS.md](file:///home/hollowheap/repos/nixos-config/.artifacts/DECISIONS.md)
- Specifications: [.artifacts/SPECS.md](file:///home/hollowheap/repos/nixos-config/.artifacts/SPECS.md)
- [x] T105 [S44]: Close ledger case for S44
  - Verify: grep -q "primaryScale" modules/options/desktop.nix && grep -q "config.desktop.primaryScale" home/modules/programs/hyprland/hyprland.nix && grep -q "config.desktop.primaryScale" roles/desktop/system/default.nix
  - Detail: tasks/T105.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T106 [S45]: Close ledger case for S45
  - Verify: test -f home/modules/programs/hyprland/keybinds.nix && grep -q "../../../lib/hyprland.nix" home/modules/programs/hyprland/keybinds.nix && ! grep -q "bind = map mkArgs" home/modules/programs/hyprland/hyprland.nix
  - Detail: tasks/T106.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08

- [x] T107 [S46]: Close ledger case for S46
  - Verify: test -f home/modules/environment/compositor.nix && grep -q "desktop.compositor" home/modules/environment/compositor.nix && grep -q "config.desktop.compositor" home/modules/programs/hyprland/hyprland.nix
  - Detail: tasks/T107.md
  - Cases: C01, C02, C03, C04, C05, C06, C07, C08
