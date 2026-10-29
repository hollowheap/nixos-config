{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption;
  inherit (lib.types) int listOf package submodule str unspecified;

  fontType = submodule {
    options = {
      name = mkOption {
        type = str;
        description = "Name of the font family.";
      };
      package = mkOption {
        type = package;
        description = "Package providing the font.";
      };
    };
  };

  cfg = config.styles.fonts;
in
{
  options = {
    styles.fonts = {
      features = mkOption {
        type = listOf str;
        default = [
          "calt"
          "cv03"
          "cv09"
          "cv10"
          "cv41"
          "cv42"
          "cv43"
          "cv62"
          "cv65"
          "cv98"
          "cv99"
          "ss03"
          "ss05"
          "ss07"
          "ss08"
          "ss09"
          "ss10"
          "ss11"
          "zero"
        ];
        description = "OpenType stylistic and ligature features for Maple Mono.";
      };

      monospace = mkOption {
        type = fontType;
        default = {
          name = config.desktop.fonts.monospace;
          package = pkgs.maple-mono-custom;
        };
        description = "Monospace font for terminals and code editors.";
      };

      sansSerif = mkOption {
        type = fontType;
        default = {
          name = config.desktop.fonts.sansSerif;
          package = pkgs.google-fonts.override { fonts = [ "Sora" ]; };
        };
        description = "Sans-serif font for UI and desktop applications.";
      };

      serif = mkOption {
        type = fontType;
        default = {
          name = config.desktop.fonts.serif;
          package = pkgs.google-fonts.override { fonts = [ "Literata" ]; };
        };
        description = "Serif font for documents.";
      };

      emoji = mkOption {
        type = fontType;
        default = {
          name = config.desktop.fonts.emoji;
          package = pkgs.noto-fonts-color-emoji;
        };
        description = "Emoji font.";
      };

      sizes = {
        applications = mkOption {
          type = int;
          default = config.desktop.fonts.sizes.applications;
          description = "Font size for general applications.";
        };

        desktop = mkOption {
          type = int;
          default = config.desktop.fonts.sizes.desktop;
          description = "Font size for desktop elements.";
        };

        popups = mkOption {
          type = int;
          default = config.desktop.fonts.sizes.popups;
          description = "Font size for popups and notifications.";
        };

        terminal = mkOption {
          type = int;
          default = config.desktop.fonts.sizes.terminal;
          description = "Font size for terminal emulators.";
        };
      };
    };

    theme.fonts = mkOption {
      type = unspecified;
      default = config.styles.fonts;
      description = "Alias to styles.fonts for backwards compatibility.";
    };
  };

  config = {
    home.packages = [
      cfg.monospace.package
      cfg.sansSerif.package
      cfg.serif.package
      cfg.emoji.package
      pkgs.noto-fonts
    ];

    fonts.fontconfig = {
      enable = true;
      hinting = "slight";
      defaultFonts = {
        monospace = [ cfg.monospace.name ];
        sansSerif = [ cfg.sansSerif.name ];
        serif = [ cfg.serif.name ];
        emoji = [ cfg.emoji.name ];
      };
    };

  };
}
