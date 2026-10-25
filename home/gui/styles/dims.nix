{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption;
  inherit (lib.types) int number unspecified;
in
{
  options = {
    styles.dims = {
      # Standard Border Options
      border = {
        size = mkOption {
          type = int;
          default = 1;
          description = "Standard window border thickness.";
        };

        radius = mkOption {
          type = int;
          default = 8;
          description = "Corner rounding radius for standard windows.";
        };

        rounding_power = mkOption {
          type = number;
          default = 2.0;
          description = "Continuous rounding (squircle) power for standard windows.";
        };
      };

      # Small Border Options
      borderSmall = {
        size = mkOption {
          type = int;
          default = 1;
          description = "Thin window border thickness for specific UI elements.";
        };

        radius = mkOption {
          type = int;
          default = 4;
          description = "Corner rounding radius for thin-bordered UI elements.";
        };

        rounding_power = mkOption {
          type = number;
          default = 2.0;
          description = "Continuous rounding (squircle) power for thin-bordered elements.";
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
    };

    theme.dims = mkOption {
      type = unspecified;
      default = config.styles.dims;
      description = "Alias to styles.dims for backwards compatibility.";
    };
  };
}
