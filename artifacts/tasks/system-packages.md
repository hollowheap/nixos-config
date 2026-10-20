# Task: System Environment, Packages & Containers (from overview.md)

- [x] **Custom Option:** Declarative `users.adminUsers` list option in `modules/options/users.nix`.
- [x] **User Accounts:** Automated user generation for `hollowheap` (admin) and `steve` with default zsh shell.
- [x] **Group Assignments:** Privilege groups (`wheel`, `tss`, `networkmanager`, `i2c`, `video`, `podman`).
- [x] **Container Runtime Development:** Enabled `virtualisation.podman` with `dockerCompat = true`, `dockerSocket.enable = true`, `defaultNetwork.settings.dns_enabled = true`, and `podman-compose` in `modules/virtualisation/podman.nix`.
- [x] **Binary Compatibility:** `programs.nix-ld.enable = true` for unpatched dynamic FHS binaries.
- [x] **System Packages:** System utilities (`brightnessctl`, `wget`, `tpm2-tss`, `home-manager`).
- [x] **Flake Modularization:** Extracted inline `packagesConfig`, `nixSettingsConfig`, and `stateVersionConfig` into `modules/system/nix.nix` and `modules/system/nixpkgs.nix`.
- [x] **Package Discovery Overlay:** Recursive directory traversal in `pkgs/default.nix` with camelCase namespacing and hidden-file filtering, exposed via `overlays.default`.
- [x] **Workspace DevShell:** Added `devShells.x86_64-linux.default` with `git`, `sops`, and `nixfmt`.
- [x] **Host Secret Management:** `sops-nix` using `/etc/ssh/ssh_host_ed25519_key` with automatic service restarts (`NetworkManager`, `ddclient`).
- [x] **Automated System Store Hygiene:** `nix.gc` timers and `nix.settings.auto-optimise-store` deduplication.
