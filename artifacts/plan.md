# NixOS Plan

## Objective
Provision and manage host-level NixOS architecture, kernel parameters, hardware drivers, bootloader security, system daemons, authentication sub-systems, host secret management, and sovereign self-hosted infrastructure.

## Master List of Goals
- [x] Partition disk and subvolumes with Disko (LUKS encryption, BTRFS subvolumes: root, home, log, persist, nix, swap)
- [ ] Implement root ephemeral filesystem wipe and Impermanence bind mounts (`/persist`)
- [x] Configure declarative GRUB EFI bootloader with TPM2 auto-unlock and `sbctl` signing hooks
- [x] Package double-minegrub-menu (Lxtharia/double-minegrub-menu) and configure declarative GRUB double menu
- [ ] Enroll Secure Boot keys (sbctl) on host firmware
- [x] Implement Flake architecture decoupling system and user space
- [x] Configure display manager, authentication, and session routing (Noctalia Greeter, UWSM, Hyprland)
- [x] Establish host secret management (`sops-nix`) and dynamic DNS (`services.duckdns`)
- [x] Stabilize hardware drivers and kernel parameters (Nvidia open modules, ACPI suspend preservation, VA-API decoding, acpilight)
- [x] Configure audio subsystem (PipeWire, ALSA, PulseAudio) and Bluetooth (audio sinks/sources)
- [x] Configure hardened DNS (Cloudflare DNS-over-TLS), firewall, and declarative NetworkManager profiles via SOPS
- [x] Deploy sovereign self-hosted mesh network (Headscale, Tailscale daemon, Vaultwarden, Caddy reverse proxy)
- [ ] Enforce WebAuthn PAM authentication challenges and system security hardening

## Tasks

### Device Profiles & Module Decoupling
- [x] Dedicated profile directories (`profiles/desktop/`, `profiles/laptop/`) with uniform recursive `default.nix` module loaders.
- [x] Profile-exclusive configurations relocated directly into profile folders (`profiles/desktop/configuration.nix` for self-hosted services, duckdns secret, and `hardware.i2c.enable = true;`; `profiles/laptop/configuration.nix` for `power-profiles-daemon` and Nvidia fine-grained power management).
- [x] Cleaned `modules/` eliminating all `config.profile` `mkIf` conditionals.
- [x] Enabled `hardware.i2c.enable = true;` for external monitor brightness DDC/CI control.
- [x] Verified with `nixos-rebuild dry-build --flake . --show-trace`.

### Storage & Filesystems
- [x] **Disko Partitioning:** Declarative GPT partitioning, 1GB EFI ESP (`/boot`), LUKS container (`crypted`, `allowDiscards = true`), and BTRFS subvolumes (`root`, `home`, `log`, `persist`, `nix`, `swap`).
- [x] **Filesystem Configuration:** Mount options with `compress=zstd` and `noatime`; `neededForBoot = true` for `/persist` and `/var/log`; 16GB swap file.
- [ ] **Impermanence (`/persist`):** Bind mounts for persistent host state (SSH host keys, NetworkManager connections, machine-id, system logs).
- [ ] **Ephemeral Root Rollback:** Root subvolume wipe on boot or tmpfs-on-root.

### Bootloader & Secure Boot
- [x] **Declarative GRUB:** EFI support, cryptodisk, OS prober, and TPM module parameters (`--disable-shim-lock`, `--modules=tpm`).
- [x] **TPM2 Initrd Unlock:** Systemd-initrd with `tpm2-device=auto`, `tpm2-measure-pcr=yes`, and PCR phases.
- [x] **Secure Boot Signing Hooks:** `boot.loader.grub.extraInstallCommands` running `sbctl sign` on EFI binaries and kernels.
- [x] **Plymouth Splash & Silent Boot:** Minecraft plymouth theme, silent kernel flags (`quiet`, `systemd.show_status=auto`, `splash`), and early console font setup (`Lat2-Terminus16`).
- [x] **Double Minegrub Menu Theme:** Package double-minegrub-menu trio (minegrub-theme, minegrub-world-sel-theme, double-minegrub-menu) in pkgs/ and enable boot.loader.grub.theme = pkgs.double-minegrub-menu; with declarative /theme/mainmenu.cfg redirection.
- [ ] **Secure Boot Key Enrollment:** Manual `sbctl` key generation and enrollment on host firmware.

### Hardware, Drivers & Multimedia
- [x] **Nvidia Driver Stack:** Open kernel modules (`hardware.nvidia.open = true`), modesetting, latest kernel packages, and ACPI memory preservation (`NVreg_PreserveVideoMemoryAllocations=1`).
- [x] **Graphics Acceleration:** 32-bit graphics libraries and `nvidia-vaapi-driver` hardware decoding.
- [x] **Audio Subsystem:** PipeWire service with ALSA, 32-bit ALSA support, and PulseAudio emulation.
- [x] **Bluetooth Subsystem:** Hardware Bluetooth enabled with `Enable = "Source,Sink,Media,Socket"` profiles and redistributable firmware.
- [x] **CPU & Display Controls:** Intel microcode updates, coretemp sensors, `acpilight`, and `i2c-dev` for DDC/CI external monitor brightness.

### Networking, Firewall & DNS
- [x] **Firewall:** Open TCP ports 80/443 and UDP port 3478 (STUN/DERP).
- [x] **DNS-over-TLS:** `systemd-resolved` configured with Cloudflare security DNS (`security.cloudflare-dns.com` over TLS).
- [x] **NetworkManager:** `iwd` backend with declarative WiFi and 802.1x enterprise profiles populated from SOPS secret `wireless_env`.
- [x] **Tailscale Client:** `services.tailscale.enable = true` host daemon.
- [x] **Dynamic DNS & Loopback:** `services.duckdns` dynamic IP updater and `networking.hosts` 127.0.0.1 domain overrides for NAT hairpin bypass.

### Session, Display & Authentication Daemons
- [x] **Display Manager & Greeter:** Noctalia Greeter service with cursor styling, custom resolution scaling, and passwordless admin user synchronization.
- [x] **Compositor & Session Routing:** Hyprland unstable package integrated with UWSM session daemon support.
- [x] **Polkit:** `security.polkit.enable = true` system privilege authorization.
- [ ] **WebAuthn PAM Hardening:** Route biometric and hardware token challenges to local PAM agent (`hyprpolkitagent` / fprintd / sudo integration).

### Users & System Environment
- [x] **Custom Option:** Declarative `users.adminUsers` list option in `modules/options/users.nix`.
- [x] **User Accounts:** Automated user generation for `hollowheap` (admin) and `steve` with default zsh shell.
- [x] **Group Assignments:** Privilege groups (`wheel`, `tss`, `networkmanager`, `i2c`, `video`).
- [x] **Binary Compatibility:** `programs.nix-ld.enable = true` for unpatched dynamic FHS binaries.
- [x] **System Packages:** System utilities (`brightnessctl`, `wget`, `tpm2-tss`, `home-manager`).

### Theming & Custom Packages (`pkgs/`)
- [x] **Package Discovery Overlay:** Auto-mapping overlay in `pkgs/default.nix`.
- [x] **MacTahoe Themes:** `mactahoe-gtk-theme` and `mactahoe-icon-theme` derivation packages.

### Sovereign Infrastructure & Self-Hosted Services
- [x] **DNS Loopback:** Localhost routing for base, headscale, and mesh vault domains.
- [x] **Headscale Mesh:** Self-hosted WireGuard control plane with MagicDNS, base domain, search domains, and extra A records.
- [x] **Vaultwarden:** Bitwarden-compatible vault running on `127.0.0.1:8222` bound to MagicDNS domain. Configured declarative signups (`SIGNUPS_ALLOWED = true`, `SIGNUPS_DOMAINS_WHITELIST = "gmail.com"`) and `environmentFile` for `ADMIN_TOKEN`.
- [x] **Dynamic DNS (ddclient):** Synchronize public IP with DuckDNS via `services.ddclient`.
- [x] **Caddy Reverse Proxy:** Reverse proxy terminating TLS for Headscale and Vaultwarden using standard automatic Let's Encrypt certificates.
- [x] **Tailscale Declarative Settings:** Configured `extraSetFlags = [ "--operator=hollowheap" ]` and `useRoutingFeatures = "both"` in `modules/services/network-services.nix`.
- [x] **Tailscale Host Registration:** Local host connects directly to local coordinator via `tailscale up --login-server http://127.0.0.1:8080`, preserving state in `/var/lib/tailscale`. Reusable preauth keys reserved for secondary/remote machines.

### Secrets & System Maintenance
- [x] **Host Secret Management:** `sops-nix` using `/etc/ssh/ssh_host_ed25519_key` with automatic service restarts (`NetworkManager`, `ddclient`).
- [x] **Automated System Store Hygiene:** `nix.gc` timers and `nix.settings.auto-optimise-store` deduplication.

## Validation
- [x] `nixos-rebuild dry-build --flake . --show-trace` evaluates without errors.
- [ ] Automated Nix store optimization verifies store space deduplication.
- [ ] GRUB menu visually loads `double-minegrub-menu` upon system reboot.
- [ ] Impermanence bind mounts preserve host keys and state across reboot with wiped root.

## Architecture
* **System vs User Space Separation:** Host-level NixOS controls system daemons, hardware drivers, kernel parameters, Disko partitioning, and root-level secrets. User space (shell configurations, GPG/SSH agent sockets, user applications, `rbw` CLI) is strictly decoupled and delegated to Home Manager (`repos/home-manager`).
* **Profile Architecture:** Machine-specific hardware and services are isolated inside self-contained profile directories (`profiles/desktop/`, `profiles/laptop/`) with dynamic loaders, removing cross-module conditionals.
* **Secrets Lifecycle:** Host credentials (`secrets.yaml`) are encrypted with age/ed25519 and pgp keys, decrypted at boot by `sops-nix` into `/run/secrets`, and injected into systemd units.

## Scope
### Included
* Host-level NixOS definitions and hardware modules.
* Disko partition layout, LUKS encryption, BTRFS subvolumes, and ephemeral root impermanence.
* Bootloader, Plymouth splash, GRUB themes (`double-minegrub-menu`), and Secure Boot signing hooks.
* Hardware drivers (Nvidia, Intel microcode, Bluetooth, PipeWire, i2c DDC/CI).
* Networking, Cloudflare DNS-over-TLS, declarative NetworkManager profiles, Tailscale, and firewall.
* Host self-hosted services (Headscale, Vaultwarden, Caddy).
* System user administration and `adminUsers` option.

### Excluded
* User-layer authentication agents: `gpg-agent`, `ssh-agent`, and `rbw` Bitwarden CLI client (managed exclusively in `home-manager`).
* User desktop configurations, dotfiles, and user package manifests.

## Tech Stack
* Languages: Nix
* Operating System: NixOS (Channel: `nixpkgs-unstable` / `release-26.05`)
* Partitioning & Filesystems: Disko, LUKS, BTRFS
* Boot & Security: GRUB, systemd-boot initrd, TPM2, sbctl, sops-nix
* Display & Session: Noctalia Greeter, UWSM, Hyprland
* Audio & Network: PipeWire, NetworkManager (iwd), systemd-resolved (DoT), Tailscale
* Services: Headscale, Vaultwarden, Caddy, duckdns

## Risks & Rollback
- [ ] **Bootloader Theme Failure:** If `double-minegrub-menu` fails to render, GRUB falls back to default text mode without preventing system boot.
- [ ] **Impermanence Misconfiguration:** Risk of losing host keys or NetworkManager connections if `/persist` bind mounts are improperly mapped; mitigation is creating backup snapshots before enabling root wipe.

## Known Issues
- [x] Replaced empty pkgs/hollow-knight-grub-theme.nix stub with complete pkgs/double-minegrub-menu.nix derivation bundle.
