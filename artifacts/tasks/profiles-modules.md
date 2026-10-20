# Task: Device Profiles & Module Decoupling (from overview.md)

- [x] Dedicated profile directories (`profiles/desktop/`, `profiles/laptop/`) with uniform recursive `default.nix` module loaders.
- [x] Create `lib/default.nix` providing `scanModules` and `mkModuleLoader` to eliminate repetitive 9-line loader boilerplates.
- [x] Refactor `modules/default.nix`, `profiles/desktop/default.nix`, and `profiles/laptop/default.nix` to use `(import ../lib).mkModuleLoader ./.` without `builtins.path` wrappers.
- [x] Profile-exclusive configurations relocated directly into profile folders (`profiles/desktop/configuration.nix` for self-hosted services, duckdns secret, and `hardware.i2c.enable = true;`; `profiles/laptop/configuration.nix` for `power-profiles-daemon` and Nvidia fine-grained power management).
- [x] Clean `modules/` eliminating all `config.profile` `mkIf` conditionals.
- [x] Verified with `nix flake check --no-build` and `nix build .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run`.
