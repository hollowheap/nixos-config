# Architectural Decisions

## Active Decisions (Bootloader & Display Transition)

- [x] D01: Patch double-minegrub-menu timeout to 3s and set boot.loader.timeout to 3s | Why: Reduces hardcoded 15s wait to user's desired 3s buffer to hit keys.
- [x] D02: Document motherboard UEFI firmware POST banner as hardware firmware boundary | Why: UEFI vendor POST messages precede bootloader control and require BIOS setup configuration.
- [x] D03: Implement flicker-free boot with Early KMS i915 and GRUB EFI GOP keep | Why: Eliminates black screen flashes caused by late KMS mode resets during Plymouth and greeter transition.

## Historical Settled Decisions

- [x] D04: Partition system via Disko with GPT, 1GB ESP, LUKS crypted container, and BTRFS subvolumes | Why: Provides declarative drive layout with full-disk encryption and structured snapshot subvolumes.
- [x] D05: Unlock LUKS root container via systemd-initrd and TPM2 PCR measurement | Why: Enables automated, hardware-bound disk decryption without manual passphrase entry on trusted boot.
- [x] D06: Secure bootloader chain with GRUB, sbctl signing hooks, and Minecraft Plymouth theme | Why: Authenticates kernel and bootloader under UEFI Secure Boot while delivering custom graphical splash.
- [x] D07: Deliver multi-tier boot theme via double-minegrub-menu derivation bundle in pkgs/ | Why: Packages Minecraft world selection and title themes with custom GRUB menu redirections.
- [x] D08: Decouple Nvidia proprietary driver and Prime offload into profiles/laptop/nvidia.nix | Why: Enforces module purity by isolating machine-specific GPU drivers from generic hardware modules.
- [x] D09: Preserve Nvidia video memory across ACPI sleep states via NVreg_PreserveVideoMemoryAllocations=1 | Why: Prevents desktop GPU freeze and memory corruption upon resume from suspend.
- [x] D10: Deploy PipeWire with 32-bit ALSA support and PulseAudio emulation | Why: Standardizes low-latency modern audio routing across native and legacy applications.
- [x] D11: Implement recursive module discovery via lib/default.nix (scanModules, mkModuleLoader) | Why: Eliminates tedious manual module imports and prevents forgotten module bugs.
- [x] D12: Implement recursive package overlay in pkgs/default.nix with camelCase namespacing | Why: Exposes local package derivations cleanly to overlays.default without hardcoded derivation listings.
- [x] D13: Deploy rootless Podman with Docker CLI compatibility and socket aliasing | Why: Provides rootless container execution for developer tooling while maintaining docker CLI compatibility.
- [x] D14: Enforce DNS-over-TLS using systemd-resolved and Cloudflare security endpoints | Why: Encrypts upstream DNS queries against ISP sniffing and network interception.
- [x] D15: Manage wireless profiles declaratively via NetworkManager iwd backend and sops-nix | Why: Keeps Wi-Fi network credentials version-controlled and encrypted in git.
- [x] D16: Suppress boot terminal console noise (consoleLogLevel = 0, initrd.verbose = false, UWSM_SILENT_START = 2) | Why: Silences harmless ACPI BIOS firmware warnings and session startup noise for clean graphical boot.
- [x] D17: Manage secrets declaratively via sops-nix and host SSH ed25519 age keys | Why: Keeps encrypted secrets checked into git while restricting decryption strictly to the physical host.
- [x] D18: Deploy removable media and mobile device integration via udisks2, gvfs, and usbmuxd | Why: Allows user-space file managers and daemons to mount USB drives, access trash, and interact with iOS devices.
- [x] D19: Enable automated thermal and power profile management via thermald and power-profiles-daemon | Why: Prevents thermal throttling cliffs on Intel laptop hardware while allowing dynamic desktop power states.
- [x] D20: Enable automated monthly BTRFS filesystem scrubbing across all subvolumes | Why: Periodically verifies cryptographic block checksums to detect and report silent SSD bitrot.
- [x] D21: Deploy sovereign mesh networking via Headscale, Caddy TLS proxy, and DuckDNS ddclient | Why: Provides private encrypted cross-device mesh connectivity with sovereign control plane.
- [x] D22: Deploy self-hosted Vaultwarden instance bound strictly to local loopback behind Caddy proxy | Why: Isolates sovereign password vault service behind TLS reverse proxy and private mesh.
- [x] D23: Standardize desktop greeter and display manager via greetd and noctalia-greeter | Why: Delivers Wayland-native greeter session with passwordless admin user synchronization.
- [x] D24: Integrate Hyprland compositor with UWSM systemd session management | Why: Wraps Wayland compositor in proper systemd user target lifecycle and environment management.
- [x] D25: Automate Nix store hygiene via weekly nix.gc and auto-optimise-store deduplication | Why: Automatically reclaims disk space from obsolete generations and hard-links duplicate store files.

## Non-Goals
- Modifying proprietary motherboard UEFI firmware ROM/NVRAM to hide hardware POST logo.
- Removing Plymouth splash screen.
- Ephemeral root filesystem wipe / tmpfs-on-root Impermanence (persistent BTRFS subvolumes used directly).
- Biometric authentication and WebAuthn PAM challenges (no biometric hardware present).
- Passive TPM2 disk decryption without user authorization (avoids zero-factor unlock).
