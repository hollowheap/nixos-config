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
            fingers = 2;
            direction = "horizontal";
          };
          action = "workspace";
        }
        {
          pattern = {
            kind = "swipe";
            fingers = 2;
            direction = "up";
          };
          action = "fullscreen";
        }
        {
          pattern = {
            kind = "swipe";
            fingers = 2;
            direction = "down";
          };
          action = "float";
        }
        {
          pattern = {
            kind = "swipe";
            fingers = 3;
            direction = "horizontal";
          };
          action = "move";
        }
        {
          pattern = {
            kind = "swipe";
            fingers = 3;
            direction = "down";
          };
          action = "close";
        }
        {
          pattern = {
            kind = "swipe";
            fingers = 3;
            direction = "up";
          };
          action = "window-switcher";
        }
        {
          pattern = {
            kind = "edge";
            origin = "up";
            direction = "down";
          };
          action = "launcher";
        }
        {
          pattern = {
            kind = "edge";
            origin = "left";
            direction = "right";
          };
          action = "window-switcher";
        }
        {
          pattern = {
            kind = "edge";
            origin = "right";
            direction = "left";
          };
          action = "session";
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
            origin = "down";
            direction = "up";
          };
          action = "toggle-touch-keyboard";
        }
        {
          pattern = {
            kind = "longpress";
            fingers = 2;
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
          action = "toggle-touch-keyboard";
        }
      ];
      description = "Abstract touch binds consumed by the compositor.";
    };
  };
}
