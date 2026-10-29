{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption;
  inherit (lib.types) bool listOf nullOr number str submodule;

  matchType = submodule {
    options = {
      appId = mkOption {
        type = nullOr str;
        default = null;
        description = "Application ID or X11 class regex.";
      };
      title = mkOption {
        type = nullOr str;
        default = null;
        description = "Current window title regex.";
      };
      initialTitle = mkOption {
        type = nullOr str;
        default = null;
        description = "Initial window title regex.";
      };
      xwayland = mkOption {
        type = nullOr bool;
        default = null;
        description = "Match XWayland or native Wayland clients.";
      };
    };
  };

  windowRuleType = submodule {
    options = {
      name = mkOption {
        type = str;
        description = "Stable rule name.";
      };
      match = mkOption {
        type = matchType;
        default = { };
        description = "Window match criteria.";
      };
      float = mkOption {
        type = bool;
        default = false;
        description = "Float matching windows.";
      };
      center = mkOption {
        type = bool;
        default = false;
        description = "Center matching windows.";
      };
      size = mkOption {
        type = listOf str;
        default = [ ];
        description = "Window size expressions.";
      };
      opaque = mkOption {
        type = bool;
        default = false;
        description = "Mark matching windows opaque.";
      };
      pin = mkOption {
        type = bool;
        default = false;
        description = "Pin matching windows.";
      };
      persistentSize = mkOption {
        type = bool;
        default = false;
        description = "Preserve a floating window's size.";
      };
      content = mkOption {
        type = nullOr str;
        default = null;
        description = "Content type hint.";
      };
      suppressEvent = mkOption {
        type = nullOr str;
        default = null;
        description = "Window event to suppress.";
      };
    };
  };

  layerRuleType = submodule {
    options = {
      name = mkOption {
        type = str;
        description = "Stable rule name.";
      };
      namespace = mkOption {
        type = str;
        description = "Layer namespace regex.";
      };
      noAnim = mkOption {
        type = bool;
        default = false;
        description = "Disable layer animations.";
      };
      blur = mkOption {
        type = bool;
        default = false;
        description = "Blur the layer.";
      };
      blurPopups = mkOption {
        type = bool;
        default = false;
        description = "Blur layer popups.";
      };
      ignoreAlpha = mkOption {
        type = nullOr number;
        default = null;
        description = "Ignore alpha values below this threshold.";
      };
    };
  };
in
{
  options.desktop.windowRules = mkOption {
    type = listOf windowRuleType;
    default = [ ];
    description = "Compositor-neutral window policy.";
  };

  options.desktop.layerRules = mkOption {
    type = listOf layerRuleType;
    default = [ ];
    description = "Compositor-neutral layer-shell policy.";
  };

  config.desktop.windowRules = [
    {
      name = "no-maximize";
      match.appId = ".*";
      suppressEvent = "maximize";
    }
    {
      name = "screenshare-picker";
      match.initialTitle = "^(Select what to share|MainPicker)$";
      float = true;
      center = true;
      size = [
        "monitor_w*0.6"
        "monitor_h*0.6"
      ];
    }
    {
      name = "portal-file-picker";
      match.appId = "xdg-desktop-portal-gtk";
      float = true;
      center = true;
      size = [
        "monitor_w*0.55"
        "monitor_h*0.65"
      ];
    }
  ];
}
