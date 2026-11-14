# Profiles, Roles & Hosts

## Composition Boundaries

- `profiles/<device>/default.nix`: chassis policy only (desktop, laptop, vm).
- `roles/<role>/system/default.nix`: duty composition (desktop, server).
- `hosts/<host>/default.nix`: per-host composition, hardware, and boot wiring.
- `modules/`: hardware- and profile-agnostic NixOS feature modules.

## Rules

- Express host differences by importing capabilities, profiles, and roles in `hosts/<host>/default.nix`; never add `config.profile` conditionals inside `modules/`.
- Keep shared desktop constants in `modules/options/desktop.nix` instead of duplicating monitor, font, or scale values across feature modules.
- Update `tests/layout.nix` expectations if adding or renaming top-level profile, role, or host files, and verify with `nix build .#checks.x86_64-linux.layout --no-link`.
