## Workflow

1. Place device configurations under profiles/<device>/configuration.nix.
2. Ensure profiles/<device>/default.nix uses the recursive loader: (import ../../lib).mkModuleLoader ./.
3. Import the directory in host configuration: imports = [ ../../profiles/<device> ];.
4. Ensure generic modules/ remain profile-agnostic with zero profile conditionals.

## Rules

- Never introduce config.profile == ... conditionals into modules/.
- Keep profile-exclusive secrets declared directly in the profile configuration.nix.
- Stage new profile files before evaluating per nix-flake-eval.
- Verify: nix build .#nixosConfigurations.NIXPC-HOLLOWHEAP.config.system.build.toplevel --dry-run passes.

