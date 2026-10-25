{ lib, ... }:
let
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf int nullOr str submodule;
in
{
  options.desktop.shortcuts = mkOption {
    type = attrsOf (
      submodule {
        options = {
          key = mkOption {
            type = str;
            description = "Hyprland keybind string.";
          };
          workspace = mkOption {
            type = nullOr int;
            default = null;
            description = "Target workspace for move actions.";
          };
        };
      }
    );
    default = {
      close-window = { key = "SUPER + SHIFT + Q"; };
      focus-window-left = { key = "SUPER + ALT + H"; };
      move-window-to-workspace = {
        key = "SUPER + ALT + 1";
        workspace = 1;
      };
    };
    description = "Neutral verb-object shortcut catalog rendered by compositor modules.";
  };
}
