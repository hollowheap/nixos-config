{
  lib,
  ...
}:
let
  inherit (lib) mkOption;
  inherit (lib.types) bool int listOf number str submodule;
in
{
  options = {
    desktop.compositor = {
      # Window Rounding
      rounding = {
        radius = mkOption {
          type = int;
          default = 8;
          description = "Corner rounding radius for windows.";
        };

        power = mkOption {
          type = number;
          default = 2.0;
          description = "Continuous rounding (squircle) power for windows.";
        };
      };

      # Margin Options
      margin = {
        inner = mkOption {
          type = int;
          default = 8;
          description = "Inner gaps between adjacent windows.";
        };

        outer = mkOption {
          type = int;
          default = 12;
          description = "Outer gaps between windows and the edge of the monitor.";
        };
      };

      # Global Dimensions
      barHeight = mkOption {
        type = int;
        default = 20;
        description = "Global height dimension for your status bar (e.g., MangoWC).";
      };

      cursor = {
        hideOnTouch = mkOption {
          type = bool;
          default = true;
          description = "Hide the cursor on touch input.";
        };
        noHardwareCursors = mkOption {
          type = int;
          default = 2;
          description = "Hyprland cursor.no_hardware_cursors: 0 disabled, 1 enabled, 2 auto.";
        };
      };

      autostart = mkOption {
        type = listOf (
          submodule {
            options = {
              command = mkOption {
                type = str;
                description = "Command started with the compositor session.";
              };
              useUwsm = mkOption {
                type = bool;
                default = true;
                description = "Wrap the command with `uwsm app --`.";
              };
            };
          }
        );
        default = [ ];
        description = "Programs started with the compositor session.";
      };

      workspaces = {
        count = mkOption {
          type = int;
          default = 10;
          description = "Number of persistent workspaces.";
        };
        defaults = mkOption {
          type = listOf int;
          default = [
            1
            2
          ];
          description = "Workspaces marked as default.";
        };
      };
    };
  };
}
