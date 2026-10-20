# Project Overview: Goals, Scope & Acceptance

High-level roadmap and system architecture overview. Per-area execution checklists live beside this file in `artifacts/tasks/`.

## Objective
Provision and manage host-level NixOS architecture, kernel parameters, hardware drivers, bootloader security, system daemons, authentication sub-systems, host secret management, and sovereign self-hosted infrastructure.

## Scope
### Included
* Host-level NixOS definitions, kernel parameters, and hardware drivers.
* Disko partition layout, LUKS encryption, BTRFS subvolumes, and ephemeral root impermanence.
* Bootloader, Plymouth splash, GRUB themes (`double-minegrub-menu`), and Secure Boot signing hooks.
* Hardware drivers (Intel UHD microcode, PipeWire, Bluetooth, i2c DDC/CI).
* Networking, Cloudflare DNS-over-TLS, declarative NetworkManager profiles, Tailscale, and firewall.
* Host self-hosted services (Headscale, Vaultwarden, Caddy reverse proxy).
* System user administration, `users.adminUsers` option, and `podman` container runtime.
* Flake architecture, module auto-discovery (`lib.mkModuleLoader`), package overlays, and devShells.

### Excluded
* User-layer authentication agents: `gpg-agent`, `ssh-agent`, and `rbw` Bitwarden CLI client (managed exclusively in `home-manager`).
* User desktop configurations, dotfiles, user AI harnesses, and user package manifests.

## Tech Stack
* Languages: Nix
* Operating System: NixOS (Channel: `nixpkgs-unstable` / `release-26.05`)
* Partitioning & Filesystems: Disko, LUKS, BTRFS
* Boot & Security: GRUB, systemd-boot initrd, TPM2, sbctl, sops-nix
* Display & Session: Noctalia Greeter, UWSM, Hyprland
* Audio & Network: PipeWire, NetworkManager (iwd), systemd-resolved (DoT), Tailscale
* Services: Headscale, Vaultwarden, Caddy, ddclient
* Containerization: Podman, Buildah, Podman Compose

## Master List of Goals
- [x] Partition disk and subvolumes with Disko (LUKS encryption, BTRFS subvolumes: root, home, log, persist, nix, swap)
- [-] Implement root ephemeral filesystem wipe and Impermanence bind mounts (`/persist`) [DROPPED]
- [x] Configure declarative GRUB EFI bootloader with `sbctl` signing hooks
- [x] Package double-minegrub-menu and configure declarative GRUB double menu
- [ ] Enroll Secure Boot keys (sbctl) on host firmware
- [x] Implement Flake architecture decoupling system and user space with clean module loaders
- [x] Configure display manager, authentication, and session routing (Noctalia Greeter, UWSM, Hyprland)
- [x] Establish host secret management (`sops-nix`) and dynamic DNS (`services.duckdns`)
- [x] Stabilize hardware drivers and kernel parameters (Intel microcode, DDC/CI, ACPI console silencing, Nvidia decoupled to laptop profile)
- [x] Configure audio subsystem (PipeWire, ALSA, PulseAudio) and Bluetooth (audio sinks/sources)
- [x] Configure hardened DNS (Cloudflare DNS-over-TLS), firewall, and declarative NetworkManager profiles via SOPS
- [x] Deploy sovereign self-hosted mesh network (Headscale, Tailscale daemon, Vaultwarden, Caddy reverse proxy)
- [x] Enable container runtime development powered by rootless Podman and Docker socket emulation
- [-] Enforce WebAuthn PAM authentication challenges and system security hardening [DROPPED]

## Tasks
Per-area execution checklists live in `artifacts/tasks/`:
- Device Profiles & Module Decoupling → [artifacts/tasks/profiles-modules.md](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/profiles-modules.md)
- Storage, Filesystems & Bootloader → [artifacts/tasks/storage-boot.md](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/storage-boot.md)
- Hardware, Drivers & Multimedia → [artifacts/tasks/hardware-multimedia.md](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/hardware-multimedia.md)
- Networking, Firewall & Sovereign Services → [artifacts/tasks/networking-sovereignty.md](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/networking-sovereignty.md)
- Session, Display & Authentication Daemons → [artifacts/tasks/session-auth.md](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/session-auth.md)
- System Environment, Packages & Containers → [artifacts/tasks/system-packages.md](file:///home/hollowheap/repos/nixos-config/artifacts/tasks/system-packages.md)

## Validation
- [x] `nix flake check --no-build` passes with 0 exit code and zero warnings.
- [x] `nix build .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run` evaluates without trace errors.
- [ ] Automated Nix store optimization verifies store space deduplication.
- [x] GRUB menu visually loads `double-minegrub-menu` upon system reboot.
- [ ] Impermanence bind mounts preserve host keys and state across reboot with wiped root.

## Risks & Rollback
- [ ] **Bootloader Theme Failure:** If `double-minegrub-menu` fails to render, GRUB falls back to default text mode without preventing system boot.
- [ ] **Impermanence Misconfiguration:** Risk of losing host keys or NetworkManager connections if `/persist` bind mounts are improperly mapped; mitigation is creating backup snapshots before enabling root wipe.
