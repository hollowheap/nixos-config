# Repository Context

## Stack & Entrypoints
- Commands live in `AGENTS.md` under `## Essential Commands`.
- NixOS flake, x86_64-linux. Primary nixpkgs is release-26.05; `pkgs.unstable`, Home Manager packages, and the kernel track nixpkgs-unstable.
- `flake.nix` -> `flake/default.nix`: host enumeration, NixOS outputs, dynamically discovered Home Manager user files, `nixOnDroidConfigurations.fovea`, devShells, and structure checks. Home modules load with `import-tree`.
- Hosts: `hosts/<name>/default.nix` import `profiles/<class>`, `roles/<role>/system`, and host-local `hardware.nix` and `boot.nix`.
- `lacuna`: laptop profile, desktop and server roles, Intel Arc graphics, touch, HDR, Wi-Fi, Bluetooth, and RGB traits.
- `acervus`: declared headless laptop shell with a placeholder hardware config and hybrid Intel + Nvidia PRIME support; no server or desktop role.
- Termux: root `nix-on-droid.nix` -> `nixOnDroidConfigurations.fovea` on unstable aarch64.
- Home Manager is standalone: `home/hollowheap.nix` is a per-user entrypoint discovered from `home/*.nix`; `home/modules` is loaded with `import-tree`, `home/modules/environment` holds compositor abstractions, `home/modules/programs/hyprland` holds the Hyprland adapter, and `home/modules/styles` holds generic fonts and pill data. Shared desktop values come from `modules/options/desktop.nix`.

## Module Seams
- `flake/default.nix`: host directory map, NixOS composition, structure checks, Home Manager and nix-on-droid outputs.
- `tests/`: recursive domain checks (`layout`, `policy`, `hardware`, `home`, `services`, `users`).
- `profiles/<class>/default.nix`: chassis policy only; no hardware imports.
- `roles/<role>/system/`: service composition; the server role decomposes into vertical slices (`caddy`, `headscale`, `vaultwarden`, `ddclient`).
- `home/modules/environment` and `home/modules/programs/gui` hold GUI modules; `home/modules/environment/compositor.nix` owns `desktop.compositor` gaps/borders/radius; `home/modules/programs/hyprland/keybinds.nix` owns Hyprland binds/submaps with helpers in `home/lib/hyprland.nix`; `roles/desktop/system` keeps Hyprland, UWSM, and greeter system-managed. Both Hyprland and the greeter read `desktop.primaryOutput`, `desktop.primaryScale`, and `desktop.monitors`.
- `hardware/<trait>.nix`: drivers and capabilities; each host groups its traits in `hardware.nix`.
- `boot/{kernel,grub,tpm,secure-boot,minegrub,plymouth}.nix`: platform integration.
- `modules/`: generic system modules scanned recursively; `modules/system/nixpkgs.nix` owns the stable/unstable split and unfree list; `modules/options/desktop.nix` owns shared desktop values and custom desktop options.
- `home/`: per-user entrypoints are discovered from `home/*.nix`; `home/modules/{ai,cli,core,environment,programs,services,terminal,styles}` are loaded with `import-tree`; `home/modules/programs/nvim/lsp.nix` owns editor language and linter wiring.
- Secrets: `.sops.yaml` creation rules target the `lacuna` age key plus admin PGP; `secrets.yaml` is encrypted.
- Caddy uses internal TLS for loopback Headscale and Vaultwarden; `tailscaled` trusts the Caddy CA.

## RDST (Requirements, Decisions, Specs, Tasks) Lifecycle
- Requirements (`artifacts/requirements.md` / `Rxx`): user-observable outcomes and acceptance criteria.
- Decisions (`artifacts/decisions.md` / `Dxx [Rxx]`): architectural choices referencing parent requirement.
- Specs (`artifacts/specs.md` / `Sxx [Rxx] [Dxx]` with indented `  - Verify: <cmd>`): public seams, invariants, and verify command.
- Tasks (`artifacts/tasks.md` / `Txx [Sxx] [Tyy, ...]` with indented `  - Verify: <cmd>`): atomic vertical tasks; omit the blocker bracket when unblocked.
- Open questions use stable `Qxx` IDs in `artifacts/brainstorm.md` and `artifacts/requirements.md`; design carries them forward.
- Architecture (`artifacts/architecture.md`): living system shape, ownership, dependency direction, invariants, and debt; only full review/workspace audit or a boundary-changing Dxx updates it. Keep this context under 60 lines.
- Reconcile: `update` uses `sed -i` to flip `- [ ]` to `- [x]` in-place once verified.
