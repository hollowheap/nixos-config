# Implementation Plan

Master tracking for host configuration, system security, hardware profiles, and sovereign infrastructure. Architectural contracts and invariants live in `artifacts/specs.md`. Settled architectural decisions live in `artifacts/decisions.md`.

## Active Implementation Tasks (Bootloader & Display Transition)

- [x] T01 [S01] [D01] (blocked-by: none): Patch pkgs/double-minegrub-menu.nix to substitute set timeout=15 with set timeout=3 in mainmenu.cfg | Verify: grep "set timeout=3" $(nix eval --raw .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.loader.grub.theme.outPath)/mainmenu.cfg
- [x] T02 [S02] [D01] (blocked-by: T01): Set boot.loader.timeout = 3 in modules/boot/boot.nix for primary GRUB menu consistency | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.loader.timeout | grep -w 3
- [x] T03 [S03] [D02] (blocked-by: none): Document UEFI vendor POST banner boundary and BIOS Quiet Boot configuration in artifacts/tasks/storage-boot.md | Verify: grep -q "UEFI Firmware Boundary" artifacts/tasks/storage-boot.md
- [x] T04 [S04] [D03] (blocked-by: none): Add i915 kernel module to boot.initrd.kernelModules in modules/boot/boot.nix for Early KMS Intel display init | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.initrd.kernelModules | grep -q "i915"
- [x] T05 [S05] [D03] (blocked-by: T04): Add i915.fastboot=1 kernel parameter to boot.kernelParams in modules/boot/boot.nix to prevent display engine reinitialization | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.kernelParams | grep -q "i915.fastboot=1"

## Historical Completed Initiatives

### Initiative 1: Flake Architecture & Code Quality
- [x] T101 [S11] [D11] (blocked-by: none): Extract shared module discovery to lib/default.nix (scanModules, mkModuleLoader) | Verify: nix flake check --no-build
- [x] T102 [S12] [D12] (blocked-by: T101): Port recursive package discovery with camelCase namespacing to pkgs/default.nix | Verify: nix eval .#double-minegrub-menu.name
- [x] T103 [S11] [D11] (blocked-by: T101): Modularize flake.nix outputs; extract system daemon and package overlays to modules/system/ | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run
- [x] T104 [S11] [D11] (blocked-by: none): Standardize repo skills into small-pillar format with references/examples.md | Verify: test -d skills/nix-flake-eval
- [x] T105 [S11] [D11] (blocked-by: none): Add maintenance devShells.x86_64-linux.default (git, sops, nixfmt) | Verify: nix develop --command echo ok

### Initiative 2: Containerization & Development Environment
- [x] T106 [S13] [D13] (blocked-by: none): Deploy rootless Podman runtime with Docker CLI compatibility (dockerCompat = true) | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.virtualisation.podman.enable | grep true
- [x] T107 [S13] [D13] (blocked-by: T106): Expose Podman socket as Docker socket for devcontainers and compose tools | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.virtualisation.podman.dockerSocket.enable | grep true
- [x] T108 [S13] [D13] (blocked-by: T106): Configure inter-container DNS resolution (defaultNetwork.settings.dns_enabled = true) | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.virtualisation.podman.defaultNetwork.settings.dns_enabled | grep true
- [x] T109 [S13] [D13] (blocked-by: none): Grant admin users podman group membership | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.users.users.hollowheap.extraGroups | grep podman

### Initiative 3: Boot Hygiene & Terminal Noise Suppression
- [x] T110 [S22] [D16] (blocked-by: none): Set boot.consoleLogLevel = 0 and boot.initrd.verbose = false to silence ACPI BIOS error noise | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.consoleLogLevel | grep -w 0
- [x] T111 [S22] [D16] (blocked-by: none): Set UWSM_SILENT_START = 2 to silence UWSM stdout and warnings during session launch | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.environment.sessionVariables.UWSM_SILENT_START | grep '"2"'

### Initiative 4: Hardware Profile Decoupling
- [x] T112 [S14] [D08] (blocked-by: none): Decouple Nvidia driver stack from universal modules into profiles/laptop/nvidia.nix | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.hardware.nvidia.modesetting.enable | grep true
- [x] T113 [S14] [D08] (blocked-by: T112): Configure Intel UHD graphics and microcode in modules/hardware/cpu.nix | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.hardware.cpu.intel.updateMicrocode | grep true

### Initiative 5: Storage, Bootloader & System Security
- [x] T114 [S16] [D04] (blocked-by: none): Declarative GPT partitioning with Disko and dedicated BTRFS subvolumes | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.disko.devices.disk.main.type | grep disk
- [x] T115 [S17] [D05] (blocked-by: T114): Systemd initrd with TPM2 PCR unlock options for encrypted root container | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.initrd.systemd.tpm2.enable | grep true
- [x] T116 [S18] [D06] (blocked-by: T115): Secure Boot signing hooks in boot.loader.grub.extraInstallCommands via sbctl | Verify: nix eval --raw .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.boot.loader.grub.extraInstallCommands | grep sbctl
- [x] T117 [S19] [D10] (blocked-by: none): PipeWire sound server deployment with ALSA and PulseAudio emulation | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.pipewire.enable | grep true
- [x] T118 [S20] [D14] (blocked-by: none): Encrypted DNS-over-TLS using systemd-resolved and Cloudflare endpoints | Verify: nix eval --raw .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.resolved.extraConfig | grep security.cloudflare-dns.com
- [x] T119 [S21] [D15] (blocked-by: none): Declarative NetworkManager profiles with iwd backend and encrypted secrets | Verify: nix eval --raw .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.networking.networkmanager.wifi.backend | grep iwd
- [x] T120 [S23] [D17] (blocked-by: none): Host secrets decryption via sops-nix and SSH ed25519 host key | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.sops.defaultSopsFormat | grep yaml
- [x] T121 [S24] [D18] (blocked-by: none): Removable storage and device integration via udisks2, gvfs, and usbmuxd | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.udisks2.enable | grep true
- [x] T122 [S25] [D19] (blocked-by: none): Intel laptop power and thermal management via thermald and power-profiles-daemon | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.thermald.enable | grep true
- [x] T123 [S26] [D20] (blocked-by: none): Automated monthly BTRFS filesystem scrub timer across all subvolumes | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.btrfs.autoScrub.enable | grep true
- [x] T124 [S27] [D21] (blocked-by: none): Headscale WireGuard mesh control plane with Caddy reverse proxy and ddclient | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.headscale.enable | grep true
- [x] T125 [S28] [D22] (blocked-by: T124): Self-hosted Vaultwarden instance bound to loopback behind Caddy TLS proxy | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.vaultwarden.enable | grep true
- [x] T126 [S29] [D23] (blocked-by: none): Noctalia Greeter display manager with automatic admin user synchronization | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.services.displayManager.noctalia-greeter.enable | grep true
- [x] T127 [S30] [D24] (blocked-by: none): Hyprland Wayland compositor with UWSM session daemon management | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.programs.hyprland.withUWSM | grep true
- [x] T128 [S31] [D25] (blocked-by: none): Automated Nix store weekly garbage collection and deduplication | Verify: nix eval .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.nix.settings.auto-optimise-store | grep true

### Dropped Initiatives (Explicit Non-Goals)
- [-] **Ephemeral Root & Impermanence:** Dropped; state is persisted directly on BTRFS subvolumes.
- [-] **WebAuthn PAM Hardening:** Dropped; no biometric hardware present.
- [-] **Passive TPM Auto-Unlock:** Avoided to prevent zero-factor authentication.

## Reference Documents
- Architecture Contracts & Invariants: [artifacts/specs.md](file:///home/hollowheap/repos/nixos-config/artifacts/specs.md)
- Architectural Decisions: [artifacts/decisions.md](file:///home/hollowheap/repos/nixos-config/artifacts/decisions.md)
- Detailed Checklists: [artifacts/tasks/](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/)
