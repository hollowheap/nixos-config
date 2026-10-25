# Repository Context

## Stack & Entrypoints
- NixOS flake, x86_64-linux. Primary nixpkgs is release-26.05; `pkgs.unstable`, Home Manager packages, and the kernel track nixpkgs-unstable.
- `flake.nix` -> `flake/default.nix`: host enumeration, NixOS outputs, `homeConfigurations.hollowheap`, `nixOnDroidConfigurations.fovea`, devShells, and structure checks.
- Hosts: `hosts/<name>/default.nix` import `profiles/<class>`, `roles/<role>/system`, and host-local `hardware.nix` and `boot.nix`.
- `lacuna`: laptop profile, desktop and server roles, Intel Arc graphics, touch, HDR, Wi-Fi, Bluetooth, and RGB traits.
- `acervus`: declared headless laptop shell with a placeholder hardware config and hybrid Intel + Nvidia PRIME support; no server or desktop role.
- Termux: root `nix-on-droid.nix` -> `nixOnDroidConfigurations.fovea` on unstable aarch64.
- Home Manager: `home/cli` declares shared options, `home/gui` holds Hyprland, Noctalia, themes, fonts, and cursor; `roles/desktop/home` wires it into lacuna.

## Commands
- Flake check: `nix flake check`
- Domain checks: `nix build .#checks.x86_64-linux.layout`
- Lacuna dry-build: `nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run`
- Acervus dry-build: `nix build .#nixosConfigurations.acervus.config.system.build.toplevel --dry-run`
- Home Manager: `nix eval .#homeConfigurations.hollowheap.activationPackage.drvPath`
- NixOS HM version: `nix eval --raw .#nixosConfigurations.lacuna.config.home-manager.users.hollowheap.desktop.nixpkgsVersion`
- Termux config: `nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion`
- Switch: `sudo nixos-rebuild switch --flake .`

## Module Seams
- `flake/default.nix`: host directory map, NixOS composition, structure checks, Home Manager and nix-on-droid outputs.
- `tests/`: recursive domain checks (`layout`, `policy`, `hardware`, `home`, `services`, `users`).
- `profiles/<class>/default.nix`: chassis policy only; no hardware imports.
- `roles/<role>/system/`: service composition; the server role owns Headscale, Vaultwarden, Caddy, ddclient, and ingress ports.
- `roles/desktop/home`: Home Manager composition for desktop hosts; `roles/desktop/system` keeps Hyprland, UWSM, and greeter system-managed.
- `hardware/<trait>.nix`: drivers and capabilities; each host groups its traits in `hardware.nix`.
- `boot/{kernel,grub,tpm,secure-boot,minegrub,plymouth}.nix`: platform integration.
- `modules/`: generic system modules scanned recursively; `modules/system/nixpkgs.nix` owns the stable/unstable split and unfree list; `modules/options/` declares custom options.
- `home/`: `home/home.nix` base, `home/cli.nix` shared options, `home/gui.nix` visual baseline; no `default.nix` loaders inside the roots.
- Secrets: `.sops.yaml` creation rules target the `lacuna` age key plus admin PGP; `secrets.yaml` is encrypted.
- Caddy uses internal TLS for loopback Headscale and Vaultwarden; `tailscaled` trusts the Caddy CA.
