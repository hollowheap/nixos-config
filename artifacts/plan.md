# NixOS System Implementation Plan

Master tracking for host configuration, system security, hardware profiles, and sovereign infrastructure. Detailed checklists live in `artifacts/tasks/`. Architectural contracts and invariants live in `artifacts/specs.md`.

## Current Roadmap & Initiatives

### Initiative 1: Flake Architecture & Code Quality [COMPLETED]
- [x] Extract shared module discovery to `lib/default.nix` (`scanModules`, `mkModuleLoader`).
- [x] Port recursive package discovery with camelCase namespacing to `pkgs/default.nix`.
- [x] Modularize `flake.nix` outputs; extract system daemon and package overlays to `modules/system/`.
- [x] Standardize repo skills into small-pillar format with `references/examples.md`.
- [x] Add maintenance `devShells.x86_64-linux.default` (`git`, `sops`, `nixfmt`).

### Initiative 2: Containerization & Development Environment [COMPLETED]
- [x] Deploy rootless Podman runtime with Docker CLI compatibility (`dockerCompat = true`).
- [x] Expose Podman socket as Docker socket for devcontainers and compose tools.
- [x] Configure inter-container DNS resolution (`defaultNetwork.settings.dns_enabled = true`).
- [x] Grant admin users `podman` group membership.

### Initiative 3: Boot Hygiene & Terminal Noise Suppression [COMPLETED]
- [x] Set `boot.consoleLogLevel = 0;` and `boot.initrd.verbose = false;` to silence ACPI BIOS error noise.
- [x] Set `UWSM_SILENT_START = "2";` to silence UWSM stdout and warnings during session launch.

### Initiative 4: Hardware Profile Decoupling [COMPLETED]
- [x] Decouple Nvidia driver stack from universal modules into `profiles/laptop/nvidia.nix`.
- [x] Eliminate `NVRM: No NVIDIA GPU found` kernel warnings on `NIXPC-HOLLOWHEAP`.
- [x] Configure clean Intel UHD graphics and microcode in `modules/hardware/cpu.nix`.

### Initiative 5: Firmware Security & Key Enrollment [PENDING]
- [ ] Generate and enroll Secure Boot keys via `sbctl`.
- [ ] Verify signed kernel and GRUB EFI execution under UEFI Secure Boot enforcement.

### Dropped Initiatives (Explicit Non-Goals)
- [-] **Ephemeral Root & Impermanence:** Dropped; state is persisted directly on BTRFS subvolumes.
- [-] **WebAuthn PAM Hardening:** Dropped; no biometric hardware present.
- [-] **Passive TPM Auto-Unlock:** Avoided to prevent zero-factor authentication.

## Reference Documents
- Architecture Contracts & Non-Goals: [artifacts/specs.md](file:///home/hollowheap/repos/nixos-config/artifacts/specs.md)
- Project Overview & Master Goals: [artifacts/tasks/overview.md](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/overview.md)
- Per-Area Execution Checklists: [artifacts/tasks/](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/)
