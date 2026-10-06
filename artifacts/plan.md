# NixOS Plan

## Objective
Provision and manage host-level NixOS architecture, kernel parameters, hardware drivers, bootloader security, system daemons, authentication sub-systems, system secret management, and sovereign self-hosted infrastructure.

## Master List of Goals
- [ ] Establish persistent NixOS storage architecture (Disko, LUKS encryption, BTRFS subvolumes, Impermanence)
- [ ] Configure Secure Boot (`sbctl`) and declarative GRUB bootloader (Hollow Knight theme)
- [x] Implement Flake architecture decoupling system and user space
- [x] Configure display manager, authentication, and session routing (`greetd`, Noctalia Polkit/Greeter, UWSM systemd targets)
- [x] Establish system secret management (`sops-nix`) and dynamic DNS (`ddclient`)
- [x] Stabilize hardware drivers and kernel parameters (Nvidia suspend state fixes)
- [ ] Deploy sovereign self-hosted mesh network (Headscale), Vaultwarden, and Caddy reverse proxy
- [ ] Enforce WebAuthn PAM authentication and system security hardening

## Shared Overlaps (Nix & Secrets Management)
- [x] **Flake Architecture & Decoupling:** Decoupled `flake.nix` system host definitions with clean user space boundaries.
- [x] **Declarative Channel Parity:** Aligning host NixOS system packages with `nixpkgs-unstable` for kernel driver and compositor binary parity.
- [x] **System Secrets Management:** `sops-nix` host deployment using age keys with strict systemd service permissions.
- [x] **Zero-Token SSH / GPG Foundation:** Systemd socket activation for SSH and GPG daemon agents at the system level.
- [ ] **Automated System Store Hygiene:** System-level `nix.gc` timers and automatic Nix store optimization (`auto-optimise-store`).

## Tasks

### Device Profiles & Module Decoupling
- [x] Declare `options.profile` (`desktop` vs `laptop`) in `modules/options/profile.nix`
- [x] Create `profiles/desktop.nix` and `profiles/laptop.nix` with minimal profile assignment
- [x] Adapt Nvidia finegrained power management conditional on `config.profile == "laptop"` in `modules/hardware/nvidia.nix`
- [x] Create `modules/hardware/laptop-power.nix` for power-profiles-daemon conditional on `config.profile == "laptop"`
- [x] Update `modules/services/network-services.nix` to gate Caddy, Headscale, ddclient, and DNS loopback behind `profile == "desktop"`
- [x] Update `modules/security/sops.nix` to gate `duckdns_password` secret behind `profile == "desktop"`
- [x] Add `brightnessctl` to `modules/system/packages.nix`
- [x] Update `hosts/NIXPC-HOLLOWHEAP/configuration.nix` to import `profiles/desktop.nix` and keep `services.upower.enable = true`
- [x] Verify build with `nixos-rebuild dry-build --flake . --show-trace`

### System Foundation & Boot Architecture
- [ ] **System Partitioning (Disko):** Declarative LUKS encryption, BTRFS subvolumes, and root ephemeral filesystem setup.
- [ ] **Impermanence (`/persist`):** Bind mounts for persistent host state (SSH host keys, NetworkManager connections, logs).
- [ ] **Bootloader & Secure Boot:** Declarative GRUB setup with Hollow Knight theme and manual `sbctl` Secure Boot key enrollment.
- [x] **Architecture:** Decoupled `flake.nix` system configuration modules.

### Kernel, Hardware & Drivers
- [x] `boot.kernelParams` (Nvidia): Append `"nvidia.NVreg_PreserveVideoMemoryAllocations=1"` to resolve ACPI power management suspend/resume freezes.
- [x] **Networking:** System-level NetworkManager link management and `ddclient` DuckDNS dynamic IP synchronization.

### Session, Display & Authentication Daemons
- [x] **Display Manager & Greeter:** `greetd` setup with Noctalia Polkit and greeter integration.
- [x] **Session Routing:** `uwsm` system daemon support and `xdg-desktop-portal` system routing.
- [ ] `security.pam.services`: Route KeePassXC/Vaultwarden WebAuthn authentication challenges to local `hyprpolkitagent` (fprintd/sudo integration).

### Sovereign Infrastructure & Self-Hosted Services
- [x] Localhost DNS loopback: Declare `networking.hosts` mapping `127.0.0.1` to `baseDomain` and `headscaleDomain` to bypass router NAT hairpinning limitations.
- [ ] `services.headscale.enable`: Deploy self-hosted control plane for WireGuard mesh networking; enable MagicDNS for immutable internal hostnames.
- [ ] `services.vaultwarden.enable`: Deploy native container/service; inject `ADMIN_TOKEN` securely via system `sops-nix`.
- [ ] `services.caddy.enable`: Intercept incoming DuckDNS traffic; terminate Let's Encrypt SSL certificates; proxy traffic to `localhost:8080`.

### Secrets & System Maintenance
- [x] `sops-nix` Deployment: Declarative decryption of host keys and system service credentials.
- [x] `services.ssh-agent.enable` / `programs.gnupg.agent.enable`: System-wide agent socket provisioning.
- [ ] **Automated Store Hygiene (`nix.gc` & `auto-optimise-store`):** System-level garbage collection timer and block-level store deduplication.

## Architecture Topics Breakdown
- [x] **Declarative Channel Parity (Unstable vs. Stable):** Standardizing host configuration on `nixpkgs-unstable` to align Mesa, Hyprland, and kernel header binaries.
- [x] **Nvidia ACPI Suspend Optimization:** Dynamic kernel memory preservation flags preventing GPU memory corruption across system sleep states.
- [ ] **Impermanence & Secret Isolation:** Isolating runtime state from system configuration by storing sops age keys in `/persist` storage.
- [ ] **Automated Store Hygiene (`nix.gc` & `auto-optimise-store`):** Hybrid GC infrastructure lifecycle management ensuring system profiles are pruned alongside automatic block-level store deduplication.
