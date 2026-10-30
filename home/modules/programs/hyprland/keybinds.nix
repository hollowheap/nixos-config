{ config, lib, pkgs, ... }:
# Hyprland adapter for the abstract desktop.shortcuts catalog.
let
  inherit (builtins) concatLists genList;
  inherit (lib.trivial) mod;
  hypr = import ../../../lib/hyprland.nix { inherit config lib; };
  inherit (hypr) mkArgs mkDsp mkDspExec mkLuaFn catalogBinds;
  inherit (config) launchApp;
  act = name: mkDspExec config.desktop.actions.${name}.command;
in
{
  home.packages = [ pkgs.wvkbd-split ];

  wayland.windowManager.hyprland = {
    settings = {
      # Standard binds mapped to your wrapper's `_args` structure
      bind = map mkArgs (
        [
          # Active window controls
          [
            "SUPER + M"
            (mkDsp "submap(\"media\")")
          ]
          [
            "SUPER + R"
            (mkDsp "submap(\"resize\")")
          ]
          [
            "SUPER + Z"
            (mkDsp "submap(\"passthrough\")")
          ]
          [
            "SUPER + SHIFT + P"
            (mkDsp "window.pin()")
          ]
          [
            "SUPER + ALT + L"
            (mkDspExec "notify-send -t 1500 'Laptop Mode' 'Enabled (t -> `, y -> NumLock)'; hyprctl dispatch submap laptop")
          ]
          [
            "SUPER + F"
            (mkDsp "window.fullscreen({ internal = 2, client = 2 })")
          ]
          [
            "SUPER + I"
            (mkDspExec "hyprctl dispatch movetoworkspacesilent special:minimized")
          ]
          [
            "SUPER + SHIFT + I"
            (mkDspExec "hyprctl dispatch togglespecialworkspace minimized")
          ]
          [
            "SUPER + T"
            (mkDsp "window.float({ action = \"set\" })")
          ]
          [
            "SUPER + Q"
            (mkDsp "window.close()")
          ]
          [
            "SUPER + mouse:272"
            (mkDsp "window.drag()")
            { mouse = true; }
          ]
          [
            "SUPER + mouse:273"
            (mkDsp "window.resize()")
            { mouse = true; }
          ]

          # Active workspace controls
          [
            "SUPER + G"
            (mkDsp "group.toggle()")
          ]

          # App shortcuts
          [
            "SUPER + RETURN"
            (mkDspExec (launchApp config.defaultApps.terminal))
          ]
          [
            "SUPER + B"
            (mkDspExec (launchApp config.defaultApps.browser))
          ]
          [
            "SUPER + E"
            (mkDspExec (launchApp "${config.defaultApps.terminal} -e ${config.defaultApps.fileManager}"))
          ]
          [
            "SUPER + V"
            (act "clipboard")
          ]
          [
            "SUPER + SPACE"
            (act "launcher")
          ]
          [
            "SUPER + TAB"
            (mkDsp "focus({ workspace = \"previous_per_monitor\" })")
          ]
          [
            "ALT + TAB"
            (act "window-switcher")
          ]
          [
            "SUPER + ESCAPE"
            (act "session")
          ]

          # Window focus navigation
          [
            "SUPER + mouse_down"
            (mkDsp "focus({ direction = \"l\" })")
          ]
          [
            "SUPER + mouse_up"
            (mkDsp "focus({ direction = \"r\" })")
          ]
          [
            "SUPER + H"
            (mkDsp "focus({ direction = \"l\" })")
          ]
          [
            "SUPER + J"
            (mkDsp "focus({ direction = \"d\" })")
          ]
          [
            "SUPER + K"
            (mkDsp "focus({ direction = \"u\" })")
          ]
          [
            "SUPER + L"
            (mkDsp "focus({ direction = \"r\" })")
          ]

          # Window swapping
          # [ "SUPER + S" (mkDsp "window.swapsplit()") ])
          [
            "SUPER + SHIFT + mouse_down"
            (mkDsp "window.swap({ direction = \"l\" })")
          ]
          [
            "SUPER + SHIFT + mouse_up"
            (mkDsp "window.swap({ direction = \"r\" })")
          ]
          [
            "SUPER + SHIFT + H"
            (mkDsp "window.swap({ direction = \"l\" })")
          ]
          [
            "SUPER + SHIFT + J"
            (mkDsp "window.swap({ direction = \"d\" })")
          ]
          [
            "SUPER + SHIFT + K"
            (mkDsp "window.swap({ direction = \"u\" })")
          ]
          [
            "SUPER + SHIFT + L"
            (mkDsp "window.swap({ direction = \"r\" })")
          ]

          # Workspace navigation
          [
            "SUPER + SHIFT + mouse_down"
            (mkDsp "focus({ workspace = \"e-1\" })")
          ]
          [
            "SUPER + SHIFT + mouse_up"
            (mkDsp "focus({ workspace = \"e+1\" })")
          ]
          [
            "SUPER + P"
            (mkDsp "focus({ workspace = \"r-1\" })")
          ]
          [
            "SUPER + N"
            (mkDsp "focus({ workspace = \"r+1\" })")
          ]

          # Media and Brightness Keys
          [
            "XF86MonBrightnessUp"
            (act "brightness-up")
            {
              repeating = true;
              locked = true;
            }
          ]
          [
            "XF86MonBrightnessDown"
            (act "brightness-down")
            {
              repeating = true;
              locked = true;
            }
          ]
          [
            "XF86AudioRaiseVolume"
            (act "volume-up")
            {
              repeating = true;
              locked = true;
            }
          ]
          [
            "XF86AudioLowerVolume"
            (act "volume-down")
            {
              repeating = true;
              locked = true;
            }
          ]
          [
            "XF86AudioMute"
            (act "volume-mute")
            { locked = true; }
          ]
          [
            "XF86AudioPlay"
            (act "media-toggle")
            { locked = true; }
          ]
          [
            "XF86AudioPrev"
            (act "media-previous")
            { locked = true; }
          ]
          [
            "XF86AudioNext"
            (act "media-next")
            { locked = true; }
          ]

          # Other shortcuts
          [
            "SUPER + D"
            (mkLuaFn ''
              hl.dsp.focus({ workspace = "name:wallpaper" })()
              hl.dsp.submap("wallpaper")()
            '')
          ]
          [
            "SUPER + SHIFT + S"
            (act "screenshot-region")
          ]
          [
            "Print"
            (act "screenshot-region")
          ]
          [
            "SHIFT + Print"
            (act "screenshot-fullscreen")
          ]
          [
            "SUPER + Print"
            (act "screenshot-annotate")
          ]
          [
            "SUPER + SHIFT + XF86TouchpadOff"
            (mkDsp "send_shortcut({ mods = \"\", key = \"Menu\" })")
          ]
          [
            "switch:on:Lenovo Yoga Tablet Mode Control switch"
            (mkDspExec "pkill -USR2 wvkbd-mobintl || uwsm app -- ${pkgs.wvkbd-split}/bin/wvkbd-mobintl --landscape-layers landscape,landscapespecial --bg 00000000 -R 8 -L 280")
            { locked = true; }
          ]
          [
            "switch:off:Lenovo Yoga Tablet Mode Control switch"
            (mkDspExec "pkill -USR1 wvkbd-mobintl || true")
            { locked = true; }
          ]
        ]
        # Appending the dynamically generated workspace sets (1-10 and 11-20)
        ++ (concatLists (
          genList (
            i:
            let
              key = toString (mod (i + 1) 10);
              wsIdx = toString (i + 1);
            in
            [
              [
                "SUPER + ${key}"
                (mkDsp "focus({ workspace = \"${wsIdx}\" })")
              ]
              [
                "SUPER + SHIFT + ${key}"
                (mkDsp "window.move({ workspace = \"${wsIdx}\" })")
              ]
            ]
          ) 10
        ))
        ++ catalogBinds
      );
    };

    submaps = {
      wallpaper = {
        settings = {
          bind = map mkArgs [
            [
              "SUPER + D"
              (mkLuaFn ''
                hl.dsp.focus({ workspace = "previous_per_monitor" })()
                hl.dsp.submap("reset")()
              '')
            ]
            [
              "escape"
              (mkLuaFn ''
                hl.dsp.focus({ workspace = "previous_per_monitor" })()
                hl.dsp.submap("reset")()
              '')
            ]
          ];
        };
      };

      media = {
        settings = {
          bind = map mkArgs [
            [ "space" (act "media-toggle") ]
            [ "p" (act "media-toggle") ]
            [ "l" (act "media-next") ]
            [ "right" (act "media-next") ]
            [ "h" (act "media-previous") ]
            [ "left" (act "media-previous") ]
            [ "k" (act "volume-up") { repeating = true; } ]
            [ "up" (act "volume-up") { repeating = true; } ]
            [ "j" (act "volume-down") { repeating = true; } ]
            [ "down" (act "volume-down") { repeating = true; } ]
            [ "m" (act "volume-mute") ]
            [ "slash" (mkDspExec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") ]
            [ "c" (mkDspExec "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") ]
            [ "escape" (mkDsp "submap(\"reset\")") ]
            [ "return" (mkDsp "submap(\"reset\")") ]
            [ "SUPER + M" (mkDsp "submap(\"reset\")") ]
          ];
        };
      };

      resize = {
        settings = {
          bind = map mkArgs [
            [ "l" (mkDsp "layout(\"colwidth +0.05\")") { repeating = true; } ]
            [ "right" (mkDsp "layout(\"colwidth +0.05\")") { repeating = true; } ]
            [ "h" (mkDsp "layout(\"colwidth -0.05\")") { repeating = true; } ]
            [ "left" (mkDsp "layout(\"colwidth -0.05\")") { repeating = true; } ]
            [ "j" (mkDsp "window.resize({ x = 0, y = 30, relative = true })") { repeating = true; } ]
            [ "down" (mkDsp "window.resize({ x = 0, y = 30, relative = true })") { repeating = true; } ]
            [ "k" (mkDsp "window.resize({ x = 0, y = -30, relative = true })") { repeating = true; } ]
            [ "up" (mkDsp "window.resize({ x = 0, y = -30, relative = true })") { repeating = true; } ]
            [ "1" (mkDsp "layout(\"colwidth 0.33\")") ]
            [ "2" (mkDsp "layout(\"colwidth 0.50\")") ]
            [ "3" (mkDsp "layout(\"colwidth 0.67\")") ]
            [ "4" (mkDsp "layout(\"colwidth 1.0\")") ]
            [ "f" (mkDsp "layout(\"fit\")") ]
            [ "escape" (mkDsp "submap(\"reset\")") ]
            [ "return" (mkDsp "submap(\"reset\")") ]
            [ "SUPER + R" (mkDsp "submap(\"reset\")") ]
          ];
        };
      };

      passthrough = {
        settings = {
          bind = map mkArgs [
            [ "SUPER + Z" (mkDsp "submap(\"reset\")") ]
            [ "SUPER + ESCAPE" (mkDsp "submap(\"reset\")") ]
          ];
        };
      };

      laptop = {
        settings = {
          bind = map mkArgs [
            [ "t" (mkDsp "send_shortcut({ mods = \"\", key = \"grave\" })") ]
            [ "SHIFT + t" (mkDsp "send_shortcut({ mods = \"SHIFT\", key = \"asciitilde\" })") ]
            [ "y" (mkDsp "send_shortcut({ mods = \"\", key = \"Num_Lock\" })") ]
            [ "SUPER + ALT + L" (mkDspExec "notify-send -t 1500 'Laptop Mode' 'Disabled'; hyprctl dispatch submap reset") ]
            [ "SUPER + ESCAPE" (mkDspExec "notify-send -t 1500 'Laptop Mode' 'Disabled'; hyprctl dispatch submap reset") ]
          ];
        };
      };
    };
  };
}
