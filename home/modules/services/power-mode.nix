{
  config,
  lib,
  pkgs,
  ...
}: let
  primary =
    lib.findFirst (monitor: monitor.output == config.desktop.primaryOutput)
    (lib.head config.desktop.monitors)
    config.desktop.monitors;
  primaryMode = primary.mode or "2880x1800@120";
  modeParts = lib.splitString "@" primaryMode;
  powerSavingMode =
    if builtins.length modeParts == 2
    then "${builtins.head modeParts}@${toString (builtins.fromJSON (lib.last modeParts) / 2)}"
    else primaryMode;
  scale =
    if (primary.scale or null) == null
    then config.desktop.primaryScale
    else primary.scale;
  bitDepth = primary.bitdepth or 10;

  mkMonitorLua = mode: depth: let
    cm = lib.optionalString (primary.cm != null) ", cm = \"${primary.cm}\"";
  in "hl.monitor({ output = \"${primary.output}\", mode = \"${mode}\", position = \"auto\", scale = ${toString scale}, bitdepth = ${toString depth}${cm} })";

  performanceLua = mkMonitorLua primaryMode bitDepth;
  powerSavingLua = mkMonitorLua powerSavingMode 8;

  scriptBody = ''
    export PATH="${lib.makeBinPath [pkgs.coreutils pkgs.hyprland pkgs.libnotify pkgs.power-profiles-daemon]}:$PATH"

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
in {
  home.file.".config/hypr/scripts/power-mode.sh" = {
    text = "#!${pkgs.runtimeShell}\n${scriptBody}";
    executable = true;
  };

  home.packages = [(pkgs.writeShellScriptBin "power-mode" scriptBody)];
}
