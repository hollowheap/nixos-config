{ config, lib, ... }:
let
  inherit (lib) mkOption;
  inherit (lib.types) int listOf nullOr str submodule unspecified;
in
{
  options.desktop.touchscreen = {
    output = mkOption {
      type = str;
      default = config.desktop.primaryOutput;
      description = "Touchscreen output name.";
    };

    transform = mkOption {
      type = int;
      default = 0;
      description = "Touch and tablet coordinate transform (0-6).";
    };

    devices = mkOption {
      type = listOf (
        submodule {
          options = {
            name = mkOption {
              type = str;
              description = "libinput device name.";
            };
            output = mkOption {
              type = nullOr str;
              default = null;
              description = "Output for this device; defaults to the touchscreen output.";
            };
          };
        }
      );
      default = [
        { name = "wacom-hid-53b7-pen"; }
        { name = "wacom-hid-53b7-finger"; }
      ];
      description = "Touch and pen devices mapped to the touchscreen output.";
    };

    gestures = mkOption {
      type = listOf unspecified;
      default = [
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
          action = "launcher";
        }
      ];
      description = "Abstract touch gestures consumed by the compositor.";
    };

    binds = mkOption {
      type = listOf unspecified;
      default = [
        {
          pattern = {
            kind = "edge";
            origin = "d";
            direction = "u";
          };
          action = "toggle-touch-keyboard";
        }
        {
          pattern = {
            kind = "longpress";
            fingers = 3;
          };
          action = {
            dispatcher = "window.drag()";
          };
          mouse = true;
        }
        {
          pattern = {
            kind = "tap";
            fingers = 3;
          };
          action = {
            dispatcher = "window.float()";
          };
        }
      ];
      description = "Abstract touch binds consumed by the compositor.";
    };
  };
}
