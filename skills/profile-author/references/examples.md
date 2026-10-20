# Profile-Author Examples

## Bad
- Introducing `if config.networking.hostName == "NIXPC-HOLLOWHEAP"` checks into `modules/hardware/nvidia.nix`.
- Manually listing every `.nix` file inside `profiles/desktop/default.nix` imports.

## Good
- Wire desktop-specific hardware and daemons in `profiles/desktop/configuration.nix` and use `(import ../../lib).mkModuleLoader ./.` in `profiles/desktop/default.nix`.
