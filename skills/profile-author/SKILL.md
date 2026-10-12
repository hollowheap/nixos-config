---
name: profile-author
description: Checklist for adding or modifying machine profile directories (profiles/desktop, profiles/laptop).
---

Maintain clean separation between universal modules and device-specific hardware/service bundles.

## Use / Do NOT use

Use when: adding hardware-specific options (DDC/CI i2c, laptop power management, external monitor controls), or hosting profile-only daemons.
Do NOT use when: modifying universal system services (greetd, pipewire, networking).

## Workflow

1. Place device configurations directly under `profiles/<device>/configuration.nix`.
2. Ensure `profiles/<device>/default.nix` uses the recursive `.nix` loader:
   ```nix
   { lib, ... }:
   let
     files = lib.filesystem.listFilesRecursive (builtins.path { path = ./.; name = "profile"; });
     nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f && baseNameOf f != "default.nix") files;
   in
   {
     imports = nixFiles;
   }
   ```
3. Import the directory in the host definition: `imports = [ ../../profiles/<device> ];`.
4. Ensure generic `modules/` remain 100% agnostic with zero profile conditionals.

## Rules

1. Never re-introduce `config.profile == ...` conditionals into `modules/`.
2. Keep profile-exclusive secrets declared directly in the profile's `configuration.nix`.

## Verification

Dry-build evaluates without trace errors:
`nix build .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run`
