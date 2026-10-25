{ config, lib, pkgs, ... }:

let
  inherit (lib.generators) mkLuaInline;
  mkDsp = fn: { _args = mkLuaInline ''hl.dsp.${fn}''; };
  mkDspExec = cmd: { _args = mkLuaInline ''hl.dsp.exec_cmd("${cmd}")''; };
in
{
  wayland.windowManager.hyprland.settings = lib.mkIf config.desktop.touch {
    cursor.hide_on_touch = true;

    input = {
      touchdevice.output = "eDP-1";
      tablet.output = "eDP-1";
    };

    gestures = {
      workspace_swipe_touch = true;
      workspace_swipe_cancel_ratio = 0.15;
    };

    plugin.hyprgrass = {
      sensitivity = 4.0;
      long_press_delay = 400;
      resize_on_border_long_press = true;
      edge_margin = 10;
    };

    "plugin.hyprgrass.gesture" = [
      {
        pattern = {
          kind = "swipe";
          fingers = 3;
          direction = "vertical";
        };
        action = "workspace";
      }
      {
        pattern = {
          kind = "swipe";
          fingers = 3;
          direction = "horizontal";
        };
        action = "workspace";
      }
      {
        pattern = {
          kind = "swipe";
          fingers = 4;
          direction = "up";
        };
        action = "fullscreen";
      }
      {
        pattern = {
          kind = "swipe";
          fingers = 4;
          direction = "down";
        };
        action = "float";
      }
      {
        pattern = {
          kind = "edge";
          origin = "up";
          direction = "down";
        };
        action = mkDspExec "noctalia msg panel-toggle launcher";
      }
    ];

    "plugin.hyprgrass.bind" = [
      {
        pattern = {
          kind = "edge";
          origin = "d";
          direction = "u";
        };
        action = mkDspExec "pkill -SIGRTMIN wvkbd-mobintl || uwsm app -- ${pkgs.wvkbd}/bin/wvkbd-mobintl --landscape-layers landscape,landscapespecial --bg 00000000 -R 8 -L 280";
      }
      {
        pattern = {
          kind = "longpress";
          fingers = 3;
        };
        action = mkDsp "window.drag()";
        mouse = true;
      }
      {
        pattern = {
          kind = "tap";
          fingers = 3;
        };
        action = mkDsp "window.float()";
      }
    ];
  };
}
