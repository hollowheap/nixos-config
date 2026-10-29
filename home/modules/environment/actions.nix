{ lib, ... }:
let
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf str submodule;
in
{
  options.desktop.actions = mkOption {
    type = attrsOf (
      submodule {
        options.command = mkOption {
          type = str;
          description = "Command backing this desktop-shell action.";
        };
      }
    );
    default = { };
    description = "Compositor-neutral shell actions consumed by keybinding and gesture adapters.";
  };
}
