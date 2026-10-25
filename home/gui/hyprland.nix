{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) concatLists genList;
  inherit (lib.trivial) mod;
  inherit (lib.generators) mkLuaInline;

  mkArgs = args: { _args = args; };

  mkDsp =
    fn:
    mkLuaInline ''
      hl.dsp.${fn}
    '';
  mkDspExec = cmd: mkDsp "exec_cmd(\"${cmd}\")";
  mkLuaFn =
    str:
    mkLuaInline ''
      function()
        ${str}
      end'';

  shortcutAction =
    name: entry:
    {
      "close-window" = mkDsp "window.close()";
      "focus-window-left" = mkDsp ''focus({ direction = "l" })'';
      "move-window-to-workspace" = mkDsp "window.move({ workspace = \"${toString entry.workspace}\" })";
    }.${name} or (throw "Unsupported desktop shortcut: ${name}");

  catalogBinds = lib.mapAttrsToList (
    name: entry: [ entry.key (shortcutAction name entry) ]
  ) config.desktop.shortcuts;

  inherit (config) launchApp;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;

    plugins = with pkgs.hyprlandPlugins; [
      hypr-dynamic-cursors
      hyprglass
    ]
    ++ lib.optionals config.desktop.touch [ hyprgrass ];

    settings = {
      colors = {
        _var = mkLuaInline ''require("noctalia")'';
      };

      monitor = [
        {
          output = "HDMI-A-1";
          mode = "1920x1080@75";
          position = "0x0";
        }
        {
          output = "DP-1";
          mode = "1920x1080@320";
          position = "1920x0";
        }
        {
          output = "eDP-1";
          mode = "2880x1800@120";
          scale = 1.25;
          bitdepth = 10;
          cm = "srgb";
        }
      ];

      device = [
        {
          name = "wacom-hid-53b7-pen";
          output = "eDP-1";
        }
        {
          name = "wacom-hid-53b7-finger";
          output = "eDP-1";
        }
      ];

      env = map mkArgs [
        [
          "XDG_CURRENT_DESKTOP"
          "Hyprland"
        ]
        [
          "XDG_SESSION_DESKTOP"
          "Hyprland"
        ]
      ];

      config = {
        cursor = {
          no_hardware_cursors = true;
        };

        general = {
          layout = "scrolling";

          resize_on_border = true;

          border_size = config.styles.dims.borderSmall.size;
          gaps_in = config.styles.dims.margin.inner;
          gaps_out = config.styles.dims.margin.outer;

          col = {
            active_border = mkLuaInline "colors.active_border";
            inactive_border = mkLuaInline "colors.inactive_border";
          };

          snap = {
            enabled = true;
            respect_gaps = true;
          };
        };

        decoration = {
          rounding = config.styles.dims.border.radius;
          rounding_power = config.styles.dims.border.rounding_power;

          inactive_opacity = 0.7;
          active_opacity = 0.9;

          shadow = {
            enabled = true;
            color = mkLuaInline "colors.active_shadow";
            color_inactive = mkLuaInline "colors.inactive_shadow";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 2;
            noise = 0.001;
            ignore_opacity = true;
            vibrancy_darkness = 0.4;
            contrast = 0.9;
            brightness = 0.8;
            vibrancy = 0.17;
            new_optimizations = false;
          };

          motion_blur = {
            enabled = true;
          };
        };

        binds = {
          allow_workspace_cycles = true;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          disable_scale_notification = true;
          vrr = 3;
        };

        ecosystem = {
          no_update_news = true;
          no_donation_nag = true;
        };

        scrolling = {
          column_width = 0.67;
          focus_fit_method = 0;
        };

        plugin = {
          dynamic_cursors = {
            enabled = true;
            mode = "tilt";

            shake = {
              enabled = true;
            };

            hyprcursor = {
              enabled = true;
              # 0 = never nearest-neighbour: smooth instead of blocky when magnified
              nearest = 0;
              # -1 = auto-calculate target resolution based on size * shake base factor
              resolution = -1;
            };
          };
        };
      };

      "plugin\.hyprglass\.config" = {
        blur_strength = .5;
        blur_iterations = 3;
        lens_distortion = 1;
        refraction_strength = 2;
        chromatic_aberration = 0.9;
        fresnel_strength = 1;
        specular_strength = 1;
        dark = {
          brightness = 1;
          adaptive_dim = .05;
        };
        light = {
          brightness = 1;
          adaptive_boost = .05;
        };
      };

      animation = mkArgs [
        {
          enabled = true;
          leaf = "workspaces";
          style = "slidevert";
          bezier = "default";
          speed = 8;
        }
      ];

      on = mkArgs [
        "hyprland.start"
        (mkLuaFn "hl.exec_cmd(\"uwsm app -- noctalia\")")
      ];

      layer_rule = [
        {
          name = "noctalia";
          match = {
            namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$";
          };
          no_anim = true;
          blur = true;
          blur_popups = true;
          ignore_alpha = 0.5;
        }
      ];

      workspace_rule = [
        {
          workspace = "w[tv1]s[false]";
          gaps_out = config.styles.dims.margin.inner;
          gaps_in = 0;
        }
        {
          workspace = "f[1]s[false]";
          gaps_out = config.styles.dims.margin.inner;
          gaps_in = 0;
        }
      ]
      ++ (genList (
        i:
        let
          key = mod (i + 1) 10;
        in
        {
          workspace = "${toString key}";
          monitor = if (mod key 2) == 0 then "DP-1" else "HDMI-A-1";
          default = key == 1 || key == 2;
        }
      ) 10);

      window_rule =
        let
          mkFloatRule = name: match: {
            inherit name;
            inherit match;
            float = true;
          };
        in
        [
          {
            name = "no-maximize";
            match = {
              class = ".*";
            };
            suppress_event = "maximize";
          }
          {
            name = "zen-popups";
            match = {
              class = "zen-.*";
              initial_title = "(Library|About Zen)";
            };
            float = true;
            opaque = true;
          }
          {
            name = "thunderbird-popups";
            match = {
              class = "thunderbird";
              initial_title = "(Write:.*|Address Book|Reminder)";
            };
            float = true;
            opaque = true;
          }
          (mkFloatRule "zoom" {
            class = "zoom";
          })
          (mkFloatRule "discord-updater" {
            class = "discord";
            initial_title = "Discord Updater";
          })
          {
            name = "noctalia-settings";
            match = {
              class = "dev.noctalia.Noctalia";
              initial_title = "Noctalia Settings";
            };
            float = true;
            center = true;
            size = [
              "monitor_w*0.7"
              "monitor_h*0.8"
            ];
          }
          (mkFloatRule "satty" {
            class = "com.gabm.satty";
          })
          {
            name = "zen-pip";
            match = {
              class = "zen-.*";
              initial_title = "Picture-in-Picture";
            };
            float = true;
            opaque = true;
            persistent_size = true;
            content = "video";
            pin = true;
          }
        ];

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
            (mkDspExec "noctalia msg panel-toggle clipboard")
          ]
          [
            "SUPER + SPACE"
            (mkDspExec "noctalia msg panel-toggle launcher")
          ]
          [
            "SUPER + TAB"
            (mkDsp "focus({ workspace = \"previous_per_monitor\" })")
          ]
          [
            "ALT + TAB"
            (mkDspExec "noctalia msg window-switcher")
          ]
          [
            "SUPER + ESCAPE"
            (mkDspExec "noctalia msg panel-toggle session")
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
            (mkDspExec "noctalia msg brightness-up")
            {
              repeating = true;
              locked = true;
            }
          ]
          [
            "XF86MonBrightnessDown"
            (mkDspExec "noctalia msg brightness-down")
            {
              repeating = true;
              locked = true;
            }
          ]
          [
            "XF86AudioRaiseVolume"
            (mkDspExec "noctalia msg volume-up")
            {
              repeating = true;
              locked = true;
            }
          ]
          [
            "XF86AudioLowerVolume"
            (mkDspExec "noctalia msg volume-down")
            {
              repeating = true;
              locked = true;
            }
          ]
          [
            "XF86AudioMute"
            (mkDspExec "noctalia msg volume-mute")
            { locked = true; }
          ]
          [
            "XF86AudioPlay"
            (mkDspExec "noctalia msg media toggle")
            { locked = true; }
          ]
          [
            "XF86AudioPrev"
            (mkDspExec "noctalia msg media previous")
            { locked = true; }
          ]
          [
            "XF86AudioNext"
            (mkDspExec "noctalia msg media next")
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
            (mkDspExec "noctalia msg screenshot-region")
          ]
          [
            "Print"
            (mkDspExec "noctalia msg screenshot-region")
          ]
          [
            "SHIFT + Print"
            (mkDspExec "noctalia msg screenshot-fullscreen")
          ]
          [
            "SUPER + Print"
            (mkDspExec "noctalia msg screenshot-annotate")
          ]
          [
            "SUPER + SHIFT + XF86TouchpadOff"
            (mkDsp "send_shortcut({ mods = \"\", key = \"Menu\" })")
          ]
          [
            "switch:on:Lenovo Yoga Tablet Mode Control switch"
            (mkDspExec "pgrep -x wvkbd-mobintl || uwsm app -- ${pkgs.wvkbd}/bin/wvkbd-mobintl --landscape-layers landscape,landscapespecial --bg 00000000 -R 8 -L 280")
            { locked = true; }
          ]
          [
            "switch:off:Lenovo Yoga Tablet Mode Control switch"
            (mkDspExec "pkill -x wvkbd-mobintl || true")
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
            [ "space" (mkDspExec "noctalia msg media toggle") ]
            [ "p" (mkDspExec "noctalia msg media toggle") ]
            [ "l" (mkDspExec "noctalia msg media next") ]
            [ "right" (mkDspExec "noctalia msg media next") ]
            [ "h" (mkDspExec "noctalia msg media previous") ]
            [ "left" (mkDspExec "noctalia msg media previous") ]
            [ "k" (mkDspExec "noctalia msg volume-up") { repeating = true; } ]
            [ "up" (mkDspExec "noctalia msg volume-up") { repeating = true; } ]
            [ "j" (mkDspExec "noctalia msg volume-down") { repeating = true; } ]
            [ "down" (mkDspExec "noctalia msg volume-down") { repeating = true; } ]
            [ "m" (mkDspExec "noctalia msg volume-mute") ]
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

  home.packages = [
    pkgs.wvkbd
  ];

  xdg.configFile."noctalia/templates/hypr-colors.lua".source =
    ../../assets/noctalia-templates/hypr-colors.lua;
}
