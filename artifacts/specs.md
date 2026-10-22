# Specifications

## Active Specifications (Bootloader & Display Transition)

- [x] S01 [D01]: Substitute hardcoded 15-second menu timeout with 3-second timeout in double-minegrub-menu package mainmenu.cfg | Verify: grep "set timeout=3" $(nix eval --raw .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.loader.grub.theme.outPath)/mainmenu.cfg
- [x] S02 [D01]: Declare 3-second loader timeout in boot.loader.timeout for primary GRUB menu consistency | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.loader.timeout | grep -w 3
- [x] S03 [D02]: Record UEFI firmware vendor POST banner boundary and BIOS quiet-boot remediation in storage-boot task documentation | Verify: grep -q "UEFI Firmware Boundary" artifacts/tasks/storage-boot.md
- [x] S04 [D03]: Include i915 in boot.initrd.kernelModules for early KMS Intel GPU panel initialization | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.initrd.kernelModules | grep -q "i915"
- [x] S05 [D03]: Append i915.fastboot=1 to boot.kernelParams to preserve UEFI GOP framebuffer without panel mode reset | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.kernelParams | grep -q "i915.fastboot=1"

## Historical Completed Specifications

- [x] S11 [D11]: lib/default.nix exports scanModules and mkModuleLoader to discover and import .nix modules recursively | Verify: nix flake check --no-build
- [x] S12 [D12]: pkgs/default.nix auto-maps subdirectory package derivations into camelCase attributes in overlays.default | Verify: nix eval .#double-minegrub-menu.name
- [x] S13 [D13]: modules/virtualisation/podman.nix configures rootless Podman with dockerCompat = true and Docker socket emulation | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.virtualisation.podman.enable | grep true
- [x] S14 [D08]: profiles/laptop/nvidia.nix isolates Nvidia proprietary driver stack with Prime offload configuration | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.hardware.nvidia.modesetting.enable | grep true
- [x] S15 [D09]: profiles/laptop/nvidia.nix enables powerManagement.enable = true and NVreg_PreserveVideoMemoryAllocations=1 | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.hardware.nvidia.powerManagement.enable | grep true
- [x] S16 [D04]: hosts/NIXPC-HOLLOWHEAP/disko.nix declares LUKS-encrypted BTRFS root with dedicated subvolumes | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.disko.devices.disk.main.type | grep disk
- [x] S17 [D05]: modules/boot/boot.nix enables systemd initrd with TPM2 PCR unlock options for crypted volume | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.initrd.systemd.tpm2.enable | grep true
- [x] S18 [D06]: modules/boot/boot.nix configures boot.loader.grub.extraInstallCommands with sbctl sign hooks | Verify: nix eval --raw .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.loader.grub.extraInstallCommands | grep sbctl
- [x] S19 [D10]: modules/services/system-services.nix enables PipeWire audio with ALSA and PulseAudio emulation | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.pipewire.enable | grep true
- [x] S20 [D14]: modules/services/network-services.nix routes DNS over TLS to Cloudflare security resolvers | Verify: nix eval --raw .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.resolved.extraConfig | grep security.cloudflare-dns.com
- [x] S21 [D15]: modules/network/networking.nix configures NetworkManager with iwd backend and encrypted wireless profiles | Verify: nix eval --raw .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.networking.networkmanager.wifi.backend | grep iwd
- [x] S22 [D16]: modules/boot/boot.nix sets consoleLogLevel = 0 and initrd.verbose = false for silent console boot | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.consoleLogLevel | grep -w 0
- [x] S23 [D17]: modules/security/sops.nix decrypts repository secrets using /etc/ssh/ssh_host_ed25519_key age key | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.sops.defaultSopsFormat | grep yaml
- [x] S24 [D18]: modules/services/system-services.nix enables udisks2, gvfs, and usbmuxd system daemons | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.udisks2.enable | grep true
- [x] S25 [D19]: profiles/laptop/configuration.nix enables thermald and power-profiles-daemon for laptop thermal management | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.thermald.enable | grep true
- [x] S26 [D20]: modules/hardware/filesystems.nix enables monthly automated BTRFS scrub timer | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.btrfs.autoScrub.enable | grep true
- [x] S27 [D21]: profiles/desktop/configuration.nix configures Headscale control plane and Caddy reverse proxy | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.headscale.enable | grep true
- [x] S28 [D22]: profiles/desktop/configuration.nix configures loopback-isolated Vaultwarden service | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.vaultwarden.enable | grep true
- [x] S29 [D23]: modules/programs/desktop.nix deploys noctalia-greeter with admin user synchronization | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.displayManager.noctalia-greeter.enable | grep true
- [x] S30 [D24]: modules/programs/desktop.nix enables Hyprland compositor with UWSM session support | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.programs.hyprland.withUWSM | grep true
- [x] S31 [D25]: modules/system/nix.nix enables weekly automated nix.gc and automatic store deduplication | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.nix.settings.auto-optimise-store | grep true
