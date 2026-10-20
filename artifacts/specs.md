# NixOS System Specifications & Architecture Contracts

## System vs User Space Boundary
- **System Domain (`nixos-config`)**: Host kernel parameters, Disko partitioning, hardware drivers, systemd daemons, root secrets, container engine runtimes (`podman`), display manager (`noctalia-greeter`), and system privilege management.
- **User Domain (`home-manager`)**: User dotfiles, desktop session styling, application keybindings, user-space AI harness configurations, user shell configs, and user credential agents (`rbw`, `gpg-agent`).

## Architectural Invariants & Contracts

### 1. Profile Decoupling & Module Purity
- Universal modules under `modules/` must be 100% hardware- and profile-agnostic.
- Never introduce `config.profile == ...` conditionals into `modules/`.
- Device-specific hardware and daemons live exclusively inside `profiles/<machine>/` (e.g. `profiles/desktop/`, `profiles/laptop/`).
- Machine profiles import submodules recursively using `(import ../../lib).mkModuleLoader ./.`.

### 2. Service Isolation & Least Privilege
- Self-hosted backend daemons (Vaultwarden, Headscale) bind strictly to loopback (`127.0.0.1`) or mesh IPs (`100.64.0.1`).
- External traffic and firewall exposure (`networking.firewall.allowedTCPPorts`) is restricted exclusively to Caddy reverse proxy (`80`, `443`).
- ACME certificates use standard HTTP-01 for public WAN records; private mesh and NAT domains use `tls internal` or DNS-01 challenges.

### 3. Dynamic Module & Package Discovery
- All NixOS system modules under `modules/` are recursively discovered via `(import ../lib).mkModuleLoader ./.` in `modules/default.nix`.
- Custom package derivations under `pkgs/` are auto-discovered recursively with `kebabToCamel` directory namespacing and exposed via `overlays.default`.

### 4. Flake Output Contracts
- Host system outputs: `nixosConfigurations.<hostName>` using `inputs.nixpkgs.lib.nixosSystem`.
- Flake maintenance devShell: `devShells.x86_64-linux.default` providing `git`, `sops`, and `nixfmt`.
- Flake overlays: `overlays.default` mapping `pkgs/default.nix`.

## Explicit Non-Goals
- Packaging or managing user dotfiles or user application keybindings (delegated to `home-manager`).
- Running graphical applications as root or unconfined system daemons.
- Exposing backend database or management ports directly to the local network or public internet.
- Ephemeral root filesystem wipe / tmpfs-on-root Impermanence (persistent BTRFS subvolumes used directly).
- Biometric authentication and WebAuthn PAM challenges (no biometric hardware).
- Passive TPM2 disk decryption without user authorization (avoids 0-factor unlock).
