# NixOS System Configuration

NixOS flake for `lacuna` and `acervus`, plus a standalone Home Manager configuration for `hollowheap` and a `fovea` nix-on-droid output.

## Essential Commands

- Build / check: `nix flake check`
- Test suite: `nix build .#checks.x86_64-linux.home .#checks.x86_64-linux.ai-rendered --no-link`
- Single module: `nix eval --raw .#homeConfigurations.hollowheap.config.programs.pi-coding-agent.settings.defaultProvider`
- Home Manager build: `nix build .#homeConfigurations.hollowheap.activationPackage --no-link`
- Lacuna dry-build: `nix build .#nixosConfigurations.lacuna.config.system.build.toplevel --dry-run`
- Acervus dry-build: `nix build .#nixosConfigurations.acervus.config.system.build.toplevel --dry-run`
- Termux: `nix eval --raw .#nixOnDroidConfigurations.fovea.config.system.stateVersion`
- Switch: `sudo nixos-rebuild switch --flake .` and `home-manager switch --flake .#hollowheap`

## Conventions

- Home Manager is standalone; NixOS and user activation are separate. Verify with a dry build before switching.
- `flake.nix` delegates to `flake/default.nix`; hosts, users, checks, and nix-on-droid outputs are enumerated there.
- Hosts compose one profile, role, hardware traits, and boot policy. Imports express duty and capability, never `config.profile` checks.
- `home/modules` loads recursively with `import-tree`; per-user entrypoints live at `home/<user>.nix`.
- Shared desktop values live in `modules/options/desktop.nix`; feature modules wire them. Do not duplicate monitor or font values.
- `home/modules/programs/nvim/lsp.nix` owns editor language and linter wiring; `completion.nix` owns Blink sources and ghost text; `keymaps.nix` owns the `r`/`s` operator and surround prefixes.
- AI harnesses are adapters over one `ai.*` schema; model and effort are adapter-local, and Pi-only MCP exposure is added in the renderer.
- Backend daemons bind loopback or mesh IPs; expose traffic only through Caddy.
- Keep host kernel, disko, drivers, systemd, and root secrets in this repo; user dotfiles live in `home/`.
- Modules stay hardware- and profile-agnostic; use imports for capability and duty.
- Declarative TDD: assert the public seam in `tests/<domain>.nix` or `nix eval` first, then implement minimal wiring.
- Stage untracked files with `git add -N` before flake evaluation.
- Never expose secrets or keys. Never skip tests, weaken assertions, or disable compiler/lint gates to force a pass.
- Never run binary dumps or brute-force CLI flags; yield after two failed lookups.
- Never force-push without `--force-with-lease`; create a backup branch before history rewrites.
- Never move safety rules into skills, never include workspace-record pointers here, and never write test pass counts here.
- Use project skills for multi-step RDST, harness, and review workflows.
