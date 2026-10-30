{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption;
  inherit (lib.types) bool float int listOf nullOr str submodule;

  monitorType = submodule {
    options = {
      output = mkOption {
        type = str;
        description = "DRM output name, for example eDP-1.";
      };
      mode = mkOption {
        type = nullOr str;
        default = null;
        description = "Resolution and refresh rate, for example 2880x1800@120.";
      };
      position = mkOption {
        type = nullOr str;
        default = null;
        description = "Position in the compositor layout, for example 1920x0.";
      };
      scale = mkOption {
        type = nullOr float;
        default = null;
        description = "Per-output scale override; the primary output uses primaryScale.";
      };
      bitdepth = mkOption {
        type = nullOr int;
        default = null;
        description = "Bit depth override.";
      };
      cm = mkOption {
        type = nullOr str;
        default = null;
        description = "Color management preset.";
      };
      vrr = mkOption {
        type = nullOr int;
        default = null;
        description = "Per-output VRR mode.";
      };
      transform = mkOption {
        type = nullOr int;
        default = null;
        description = "Output transform rotation.";
      };
      disabled = mkOption {
        type = nullOr bool;
        default = null;
        description = "Whether the output is disabled.";
      };
      icc = mkOption {
        type = nullOr str;
        default = null;
        description = "ICC profile path for the output.";
      };
      supports_hdr = mkOption {
        type = nullOr int;
        default = null;
        description = "Whether the output supports HDR.";
      };
      supports_wide_color = mkOption {
        type = nullOr int;
        default = null;
        description = "Whether the output supports wide color.";
      };
      sdrbrightness = mkOption {
        type = nullOr float;
        default = null;
        description = "SDR brightness in HDR mode.";
      };
      sdrsaturation = mkOption {
        type = nullOr float;
        default = null;
        description = "SDR saturation in HDR mode.";
      };
    };
  };
in
{
  options.desktop = {
    touch = mkEnableOption "touchscreen compositor support";
    hdr = mkEnableOption "HDR compositor preference";

    primaryOutput = mkOption {
      type = str;
      default = "eDP-1";
      description = "Primary output used for scale synchronization and greeter settings.";
    };

    primaryScale = mkOption {
      type = float;
      default = 1.25;
      description = "Scale for the primary output and the login greeter.";
    };

    monitors = mkOption {
      type = listOf monitorType;
      default = [
        {
          output = "eDP-1";
          mode = "2880x1800@120";
          bitdepth = 10;
          cm = "srgb";
        }
      ];
      description = "Declarative monitor layout shared by Hyprland and the login greeter.";
    };

    fonts = {
      monospace = mkOption {
        type = str;
        default = "Maple Mono NF";
        description = "Monospace font family.";
      };
      sansSerif = mkOption {
        type = str;
        default = "Sora";
        description = "Sans-serif font family.";
      };
      serif = mkOption {
        type = str;
        default = "Literata";
        description = "Serif font family.";
      };
      emoji = mkOption {
        type = str;
        default = "Noto Color Emoji";
        description = "Emoji font family.";
      };
      sizes = {
        applications = mkOption {
          type = int;
          default = 12;
          description = "Font size for general applications.";
        };
        desktop = mkOption {
          type = int;
          default = 10;
          description = "Font size for desktop elements.";
        };
        popups = mkOption {
          type = int;
          default = 10;
          description = "Font size for popups and notifications.";
        };
        terminal = mkOption {
          type = int;
          default = 12;
          description = "Font size for terminal emulators.";
        };
      };
    };
  };
}
