# Workspace Conventions: NixOS System Configuration

## System & Architecture Guidelines
- **System vs. User Space Boundary**: Manage host kernel parameters, Disko partitioning, hardware drivers, systemd daemons, and root secrets here. Delegate user dotfiles, shell configs, and user-layer agents to `repos/home-manager`.
- **Profile Decoupling & Module Purity**: Modules under `modules/` must be strictly hardware- and profile-agnostic. Never introduce `config.profile == ...` conditionals. Isolate device-specific configs inside `profiles/<machine>/` (e.g. `profiles/desktop/`, `profiles/laptop/`).
- **Dynamic Module Discovery**: Profile folders load submodules recursively via `profiles/<device>/default.nix` (excluding `default.nix` itself).
- **Service Isolation & Least Privilege**: Backend daemons (Vaultwarden, Headscale) bind strictly to loopback (`127.0.0.1`) or mesh IPs (`100.64.0.1`). Expose traffic to external/firewall ports exclusively through Caddy reverse proxy.
- **Verification Before Switch**: Always verify changes with `nixos-rebuild dry-build --flake .` or `nix build .#nixosConfigurations.<host>.config.system.build.toplevel --dry-run` before requesting `switch`.

## Workspace Skills
SKILL.md procedures live in `skills/` (agentskills.io format). Load the matching skill before task work:
- **nix-flake-eval**: before any nix eval, build, dry-run, or check touching new files.
- **upstream-recon**: before adding or altering unfamiliar NixOS options, services, or package derivations.
- **selfhosted-service**: before deploying or altering network-facing services, Caddy reverse proxies, or DNS/TLS challenges.
- **profile-author**: before adding or refactoring machine profiles under `profiles/`.

