{ config, lib, pkgs, ... }:
let
  primary =
    lib.findFirst (monitor: monitor.output == config.desktop.primaryOutput)
      (lib.head config.desktop.monitors)
      config.desktop.monitors;
  primaryMode = primary.mode or "2880x1800@120";
  powerSavingMode = lib.replaceStrings [ "@120" ] [ "@60" ] primaryMode;
  bitDepth = primary.bitdepth or 10;

  mkMonitorLua =
    mode: depth:
    let
      cm = lib.optionalString (primary.cm != null) ", cm = \"${primary.cm}\"";
    in
    "hl.monitor({ output = \"${primary.output}\", mode = \"${mode}\", position = \"auto\", scale = ${toString config.desktop.primaryScale}, bitdepth = ${toString depth}${cm} })";

  performanceLua = mkMonitorLua primaryMode bitDepth;
  powerSavingLua = mkMonitorLua powerSavingMode 8;

  powerMode = pkgs.writeShellApplication {
    name = "power-mode";
    runtimeInputs = with pkgs; [
      coreutils
      hyprland
      libnotify
      power-profiles-daemon
    ];
    text = ''
      mode="''${1:-toggle}"

      if [ "$mode" = "toggle" ]; then
        case "$(powerprofilesctl get)" in
          performance) mode=power-saver ;;
          *) mode=performance ;;
        esac
      fi

      case "$mode" in
        performance)
          profile=performance
          monitor_lua=${lib.escapeShellArg performanceLua}
          ;;
        balanced)
          profile=balanced
          monitor_lua=${lib.escapeShellArg performanceLua}
          ;;
        power-saver|saver)
          profile=power-saver
          monitor_lua=${lib.escapeShellArg powerSavingLua}
          ;;
        status)
          printf 'profile: %s\n' "$(powerprofilesctl get)"
          exit 0
          ;;
        *)
          echo "usage: power-mode [performance|balanced|power-saver|toggle|status]" >&2
          exit 2
          ;;
      esac

      powerprofilesctl set "$profile"

      if command -v hyprctl >/dev/null 2>&1 && [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        hyprctl eval "$monitor_lua" >/dev/null
      fi

      notify-send -t 1500 "Power Mode" "$profile"
    '';
  };
in
{
  home.packages = [ powerMode ];
}
