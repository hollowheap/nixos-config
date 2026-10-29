# NixOS System Configuration

NixOS flake for `lacuna` and `acervus`, plus a `fovea` nix-on-droid output. The primary nixpkgs tracks release-26.05; user programs, Home Manager, and the kernel track unstable. Home Manager is standalone from NixOS.

## Essential Commands
- Flake check: `nix flake check`
- Domain checks: `nix build .#checks.x86_64-linux.layout`
- Lacuna dry-build: `nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run`
- Acervus dry-build: `nix build .#nixosConfigurations.acervus.config.system.build.toplevel --dry-run`
- Home Manager build: `nix build .#homeConfigurations.hollowheap.activationPackage --no-link`
- Termux: `nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion`
- NixOS switch: `sudo nixos-rebuild switch --flake .`

## Repository Layout
- `flake.nix`, `flake/`: inputs, dynamic host/user enumeration, outputs, checks.
- `hosts/`: per-host composition and host-local hardware/boot files.
- `profiles/`: chassis policy only.
- `roles/`: duty composition (`system/`).
- `hardware/`, `boot/`: drivers, capabilities, and platform integration.
- `home/`: per-user entrypoints discovered from `home/*.nix`; `home/modules` is loaded with `import-tree`; domains are `{ai,cli,core,environment,programs,services,terminal,styles}`; `home/lib/toolchains.nix` holds editor toolchain maps.
- `modules/`: NixOS modules scanned recursively; `modules/options/desktop.nix` holds shared desktop fonts, monitors, and scale.
- `pkgs/`, `assets/`: local packages and theme templates.
- `tests/`: domain flake checks loaded by `tests/default.nix`.
- `nix-on-droid.nix`: fovea Termux configuration.

## Context
- `artifacts/context.md` holds verified architecture, module seams, and the RDST lifecycle.

## Conventions
- Home Manager is standalone; `nixos-rebuild switch` applies NixOS only. Activate user config with `home-manager switch --flake .#hollowheap`.
- Per-user Home Manager entrypoints live at `home/<user>.nix`; the flake discovers them.
- Shared desktop values live in `modules/options/desktop.nix`; feature modules wire them. Do not duplicate monitor or font values.
- Keep host kernel, disko, drivers, systemd, and root secrets in this repo; user dotfiles live in `home/`.
- Modules must stay hardware- and profile-agnostic; imports express capability and duty, never `config.profile` checks.
- Backend daemons bind loopback or mesh IPs; expose traffic only through Caddy.
- Verify with a dry-build before switching.
- Declarative TDD: assert module behavior in `tests/<domain>.nix` or `nix eval` first, implement minimal wiring, and verify.
- Flake eval hygiene: stage untracked files with `git add -N` before running flake checks or evaluations.
- Skill bodies live in `skills/` (shared base) and `assets/skills/` (workspace skills); `home/lib/skill-metadata.nix` owns their metadata, and `lib/ai-skills.nix` loads both as pure data.
