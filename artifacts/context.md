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

## RDST Traceability & RDST Gates
- Traceability spine: Requirements (`Rxx`), Design (`Dxx` + architecture), Specs (`Sxx`), Tasks (`Txx`). RDST is not a phase sequence.
- Questions (`artifacts/questions.md` / `Qxx`) are canonical and grouped under meaningful H3 source headings; the heading owns origin, lens, slice, and shared scope. Do not repeat source metadata per item.
- Requirements (`artifacts/requirements.md`): user-observable outcomes, acceptance, constraints, and non-goals only. Design choices belong in `Dxx`.
- Design (`artifacts/decisions.md` + `artifacts/architecture.md`): accepted decisions only, grouped under H3 architecture categories; unresolved choices stay `Qxx`, while accepted decisions may remain `[ ]` until child specs complete. Decisions carry `Resolves`, `Supersedes`, and an `Arch` section. Architecture covers system, modules, frameworks/libraries, data/contracts, operations/security, debt, and evidence.
- Specs (`artifacts/specs.md` / `Sxx [Rxx] [Dxx]` with `Verify` and `Arch`): public seams and invariants; they inherit accepted design, never resolve an open question.
- Tasks (`artifacts/tasks.md` / `Txx [Sxx] [Tyy, ...]`): atomic verified work only; no design/spec/plan breakdown.
- Review (`artifacts/review/<slice>.md`): one record per slice with Requirements, Design, Specification, Plan, Code, and Acceptance sections. Review still runs by diff, slice, or robustness; UI/backend are optional lenses. A rejected RDST section blocks the next phase.
- Persistent review registry and skill-authoring notes: `artifacts/reviews.md` maps `Vxx` to review files; `artifacts/notes/` holds reference-framework, review-model, skill-design, skill-inventory, verification, and author-harness matrix notes.
- Reconcile: `update` refreshes architecture, questions, decisions, specs, tasks, and review gates after verification.
