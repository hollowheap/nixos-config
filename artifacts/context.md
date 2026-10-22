# Repository Context

## Stack & Entrypoints
- **Platform**: NixOS (Linux x86_64), Flake-managed system configuration.
- **System Entrypoint**: `flake.nix` -> `nixosConfigurations.NIXPC-HOLLOWHEAP`.
- **Host Root**: `hosts/NIXPC-HOLLOWHEAP/configuration.nix` (imports `modules/`, `profiles/desktop`, `profiles/laptop`).
- **Dynamic Loader**: `lib/default.nix` (`mkModuleLoader`) discovers all `.nix` modules recursively.

## Commands
- Build dry-run: `nix build .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run`
- Flake check: `nix flake check --no-build`
- Verify Secure Boot: `nix run nixpkgs#sbctl -- status`
- Switch configuration: `sudo nixos-rebuild switch --flake .`
- Artifact status: `artifacts.sh status`

## Module Seams
- **Bootloader**: `modules/boot/boot.nix` (GRUB with Secure Boot signing via `sbctl`, Minegrub theme, TPM2 LUKS unlock, Plymouth splash).
- **Hardware**: `modules/hardware/` (`bluetooth`, `cpu`, `filesystems`, `graphics`) & `profiles/laptop/nvidia.nix` (Prime offload).
- **Services**: `modules/services/` (`system-services` with greetd, udisks2, gvfs, usbmuxd, colord, fwupd; `network-services` with resolved, tailscale).
- **Security & Secrets**: `modules/security/` (`polkit.nix`, `sops.nix` with host SSH age key).
- **Desktop Session**: `modules/programs/desktop.nix` (Hyprland with UWSM, noctalia-greeter on greetd).
- **Profiles**: `profiles/desktop` (Headscale, Tailscale mesh, OpenRGB) & `profiles/laptop` (thermald, power-profiles-daemon, upower).
- **Packages**: `pkgs/default.nix` overlaying `double-minegrub-menu`, `minegrub-theme`, `minegrub-world-sel-theme`.
