# NixOS System Configuration

NixOS flake for `lacuna` and `acervus`, plus a `fovea` nix-on-droid output. The primary nixpkgs tracks release-26.05; user programs, Home Manager, and the kernel track unstable. See `artifacts/context.md` for detailed seams.

## Essential Commands
- Flake check: `nix flake check`
- Domain checks: `nix build .#checks.x86_64-linux.layout`
- Lacuna dry-build: `nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run`
- Acervus dry-build: `nix build .#nixosConfigurations.acervus.config.system.build.toplevel --dry-run`
- Home Manager: `nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath`
- Termux: `nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion`
- Switch: `sudo nixos-rebuild switch --flake .`

## Repository Layout
- `flake.nix`, `flake/`: inputs, host enumeration, outputs, checks.
- `hosts/`: per-host composition and host-local hardware/boot files.
- `profiles/`: chassis policy only.
- `roles/`: duty composition (`system/` and `home/`).
- `hardware/`, `boot/`: drivers, capabilities, and platform integration.
- `home/`: Home Manager base, CLI options, GUI tier.
- `modules/`, `pkgs/`, `assets/`: shared modules, local packages, theme templates.
- `tests/`: domain flake checks loaded by `tests/default.nix`.
- `nix-on-droid.nix`: fovea Termux configuration.

## Conventions
- Keep host kernel, disko, drivers, systemd, and root secrets in this repo; user dotfiles live in `home/`.
- Modules must stay hardware- and profile-agnostic; imports express capability and duty, never `config.profile` checks.
- Backend daemons bind loopback or mesh IPs; expose traffic only through Caddy.
- Verify with a dry-build before switching.
- Workspace skills live in `skills/`: `nix-flake-eval`, `upstream-recon`, `selfhosted-service`, `profile-author`.
