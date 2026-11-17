{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) genList;
  inherit (lib.generators) mkLuaInline;
  hypr = import ../../../lib/hyprland.nix {inherit config lib;};
  inherit (hypr) mkArgs mkDsp mkDspExec mkLuaFn mkTouchKeyboard;

  touchKeyboard = mkTouchKeyboard pkgs;
  touchCommands = {
    toggle-touch-keyboard = "pkill -SIGRTMIN wvkbd-mobintl || uwsm app -- ${touchKeyboard}";
    show-touch-keyboard = "pkill -USR2 wvkbd-mobintl || uwsm app -- ${touchKeyboard}";
    hide-touch-keyboard = "pkill -USR1 wvkbd-mobintl || true";
  };

  noctaliaGlassLayerNamespaces = [
    "noctalia-bar-main"
    "noctalia-attached-panel"
    "noctalia-panel"
    "noctalia-dock"
    "noctalia-notification"
    "noctalia-osd"
    "noctalia-window-switcher"
  ];

  mapMatch = match:
    lib.filterAttrs (_: value: value != null) {
      class = match.appId;
      inherit (match) title;
      initial_title = match.initialTitle;
      inherit (match) xwayland;
      inherit (match) modal;
    };

  mapWindowRule = rule:
    {
      inherit (rule) name;
      match = mapMatch rule.match;
    }
    // lib.filterAttrs (_: value: value) {
      inherit (rule) float;
      inherit (rule) center;
      inherit (rule) opaque;
      inherit (rule) pin;
      persistent_size = rule.persistentSize;
      no_initial_focus = rule.noInitialFocus;
    }
    // lib.optionalAttrs (rule.size != []) {inherit (rule) size;}
    // lib.optionalAttrs (rule.content != null) {inherit (rule) content;}
    // lib.optionalAttrs (rule.suppressEvent != null) {
      suppress_event = rule.suppressEvent;
    };

  mapLayerRule = rule:
    {
      inherit (rule) name;
      match = {
        inherit (rule) namespace;
      };
    }
    // lib.optionalAttrs rule.noAnim {no_anim = true;}
    // lib.optionalAttrs rule.blur {blur = true;}
    // lib.optionalAttrs rule.blurPopups {blur_popups = true;}
    // lib.optionalAttrs (rule.ignoreAlpha != null) {
      ignore_alpha = rule.ignoreAlpha;
    };
in {
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;

    plugins =
      [
        pkgs.hyprlandPlugins.hypr-dynamic-cursors
        pkgs.hyprlandPlugins.hyprglass
        pkgs.hyprlandPlugins.hyprtasking
      ]
      ++ (
        if config.desktop.touch
        then
          if !(lib.elem pkgs.hyprland.version ["0.57.0" "0.57.1" "0.57.2"])
          then throw "hyprgrass has no pin for Hyprland ${pkgs.hyprland.version}; update pkgs/hyprland-plugins/hyprgrass.nix"
          else [pkgs.hyprlandPlugins.hyprgrass]
        else []
      );

    settings = {
      colors = {
        _var = mkLuaInline (builtins.readFile ./colors.lua);
      };

      "plugin.hyprgrass.gesture" = lib.mkIf config.desktop.touch (
        map (
          gesture: {
            inherit (gesture) pattern;
            action =
              if builtins.isString gesture.action && touchCommands ? ${gesture.action}
              then mkLuaFn ''hl.dispatch(hl.dsp.exec_cmd(${builtins.toJSON touchCommands.${gesture.action}}))''
              else if builtins.isString gesture.action && config.desktop.actions ? ${gesture.action}
              then mkLuaFn ''hl.dispatch(hl.dsp.exec_cmd(${builtins.toJSON config.desktop.actions.${gesture.action}.command}))''
              else if builtins.isAttrs gesture.action
              then mkLuaFn ''hl.dispatch(hl.dsp.exec_cmd(${builtins.toJSON gesture.action.exec}))''
              else gesture.action;
          }
        )
        config.desktop.touchscreen.gestures
      );

      "plugin.hyprgrass.bind" = lib.mkIf config.desktop.touch (
        map (
          bind:
            {
              inherit (bind) pattern;
              action =
                if builtins.isString bind.action && touchCommands ? ${bind.action}
                then mkDspExec touchCommands.${bind.action}
                else if builtins.isString bind.action && config.desktop.actions ? ${bind.action}
                then mkDspExec config.desktop.actions.${bind.action}.command
                else if builtins.isAttrs bind.action && bind.action ? exec
                then mkDspExec bind.action.exec
                else mkDsp bind.action.dispatcher;
            }
            // lib.optionalAttrs (bind ? mouse) {inherit (bind) mouse;}
        )
        config.desktop.touchscreen.binds
      );

      "plugin.hyprglass.config" = {
        blur_strength = 0.65;
        blur_iterations = 2;
        lens_distortion = 0.34;
        refraction_strength = 2.80;
        refraction_spread = 0.78;
        chromatic_aberration = 0.18;
        fresnel_strength = 1.05;
        specular_strength = 1.25;
        edge_thickness = 0.04;
        bevel_strength = 0.28;
        noise_strength = 0.012;
        xray = false;
        layers = {enabled = true;};
        dark = {
          brightness = 0.88;
          adaptive_dim = 0.12;
        };
        light = {
          brightness = 1.04;
          adaptive_boost = 0.10;
        };
      };

      "plugin.hyprglass.preset" = [
        (mkArgs [
          "noctalia-clean"
          {
            inherits = "glass";
            fresnel_strength = 0.0;
            specular_strength = 0.0;
            bevel_strength = 0.0;
            lens_distortion = 0.0;
            refraction_strength = 0.45;
          }
        ])
      ];

      "plugin.hyprglass.layer" =
        [
          (mkArgs ["noctalia-wallpaper" {exclude = true;}])
          (mkArgs ["noctalia-screen-corner" {exclude = true;}])
        ]
        ++ map (
          namespace:
            mkArgs [
              namespace
              {
                preset = "noctalia-clean";
                mask_threshold = 0.55;
                mask_feather = 0.25;
              }
            ]
        )
        noctaliaGlassLayerNamespaces;

      monitor =
        map (
          monitor: let
            configured = lib.filterAttrs (_: value: value != null) monitor;
            hdr = config.desktop.hdr && configured.output == config.desktop.primaryOutput;
          in
            (
              if configured.output == config.desktop.primaryOutput
              then configured // {scale = config.desktop.primaryScale;}
              else configured
            )
            // lib.optionalAttrs hdr {
              cm = "hdredid";
              supports_hdr = 1;
            }
        )
        config.desktop.monitors;

      device =
        map (
          device: {
            inherit (device) name;
            output =
              if device.output == null
              then config.desktop.touchscreen.output
              else device.output;
          }
        )
        config.desktop.touchscreen.devices;

      gesture = [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
        }
        {
          fingers = 3;
          direction = "up";
          action = "fullscreen";
        }
        {
          fingers = 3;
          direction = "down";
          action = "float";
        }
        {
          fingers = 4;
          direction = "horizontal";
          action = "move";
        }
        {
          fingers = 4;
          direction = "down";
          action = "close";
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
          no_hardware_cursors = config.desktop.compositor.cursor.noHardwareCursors;
          hide_on_touch = config.desktop.compositor.cursor.hideOnTouch;
        };

        quirks = lib.mkIf config.desktop.hdr {
          prefer_hdr = 1;
        };

        input = lib.mkMerge [
          {
            kb_layout = config.desktop.input.layout;
            kb_variant = config.desktop.input.variant;
            kb_options = config.desktop.input.options;
            repeat_delay = config.desktop.input.repeatDelay;
            repeat_rate = config.desktop.input.repeatRate;
            touchpad.natural_scroll = true;
            virtualkeyboard.release_pressed_on_close = true;
            mouse_refocus = false;
          }
          (lib.mkIf config.desktop.touch {
            touchdevice.output = config.desktop.touchscreen.output;
            touchdevice.transform = config.desktop.touchscreen.transform;
            tablet.output = config.desktop.touchscreen.output;
            tablet.transform = config.desktop.touchscreen.transform;
          })
        ];

        gestures = lib.mkIf config.desktop.touch {
          # Single-finger touch scrolls content. Workspace switching stays on
          # the explicit three-finger hyprgrass gesture below.
          workspace_swipe_touch = false;
          workspace_swipe_cancel_ratio = 0.15;
          workspace_swipe_invert = false;
        };

        general = {
          layout = "scrolling";

          resize_on_border = true;

          border_size = 0;
          col = {
            active_border = mkLuaInline "colors.active_border";
            inactive_border = mkLuaInline "colors.inactive_border";
            nogroup_border = mkLuaInline "colors.inactive_border";
            nogroup_border_active = mkLuaInline "colors.active_border";
          };
          gaps_in = config.desktop.compositor.margin.inner;
          gaps_out = config.desktop.compositor.margin.outer;

          snap = {
            enabled = true;
            respect_gaps = true;
          };
        };

        decoration = {
          rounding = config.desktop.compositor.rounding.radius;
          rounding_power = config.desktop.compositor.rounding.power;

          inactive_opacity = 0.66;
          active_opacity = 0.80;

          shadow = {
            enabled = true;
            range = 34;
            render_power = 4;
            sharp = false;
            offset = [0 8];
            scale = 0.99;
            color = mkLuaInline "colors.active_shadow";
            color_inactive = mkLuaInline "colors.inactive_shadow";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 2;
            noise = 0.014;
            ignore_opacity = true;
            vibrancy_darkness = 0.08;
            contrast = 1.04;
            brightness = 0.88;
            vibrancy = 0.28;
            new_optimizations = true;
            xray = false;
            popups = true;
            popups_ignorealpha = 0.2;
          };

          motion_blur = {
            enabled = true;
            samples = 2;
          };

          wobble = {
            enabled = true;
            mesh = 8;
            stiffness = 460;
            damping = 34;
            mass = 0.85;
            intensity = 0.12;
            value_epsilon = 0.5;
            velocity_epsilon = 4.0;
          };
        };

        animations = {
          enabled = true;
        };

        render = {
          direct_scanout = 2;
          new_render_scheduling = true;
          async_commit = true;
        };

        binds = {
          allow_workspace_cycles = true;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          disable_scale_notification = true;
          vrr = 3;
          allow_session_lock_restore = true;
          session_lock_xray = true;
          focus_on_activate = true;
          font_family = config.desktop.fonts.sansSerif;
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
          hyprgrass = lib.mkIf config.desktop.touch {
            sensitivity = 4.0;
            long_press_delay = 400;
            resize_on_border_long_press = true;
            edge_margin = 10;
          };

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

          hyprtasking = {
            layout = "linear";
            bg_color = mkLuaInline "colors.bg_color";
            gap_size = config.desktop.compositor.margin.inner;
            border_size = 2;
            exit_on_hovered = false;
            warp_on_move_window = 1;
            close_overview_on_reload = false;
            jump = {
              enabled = false;
              label_color = mkLuaInline "colors.label_color";
              label_background = mkLuaInline "colors.label_background";
            };
            gestures = {
              enabled = true;
              # Disable 3-finger overview swipes so Hyprland's native 3-finger gestures remain intact.
              move_fingers = 0;
              open_fingers = 4;
              open_distance = 300;
              open_positive = true;
            };
            linear = {
              top = false;
              height = 300;
              scroll_speed = 1.0;
              blur = false;
            };
          };
        };
      };

      curve = [
        (mkArgs [
          "appleSheet"
          {
            type = "bezier";
            points = [
              [0.32 0.72]
              [0.0 1.0]
            ];
          }
        ])
        (mkArgs [
          "appleDecel"
          {
            type = "bezier";
            points = [
              [0.16 1.0]
              [0.3 1.0]
            ];
          }
        ])
        (mkArgs [
          "appleFluid"
          {
            type = "bezier";
            points = [
              [0.22 1.0]
              [0.36 1.0]
            ];
          }
        ])
        (mkArgs [
          "appleSnappy"
          {
            type = "bezier";
            points = [
              [0.2 0.9]
              [0.1 1.0]
            ];
          }
        ])
        (mkArgs [
          "appleSpring"
          {
            type = "spring";
            mass = 1.0;
            stiffness = 360.0;
            damping = 28.0;
          }
        ])
        (mkArgs [
          "appleSnappySpring"
          {
            type = "spring";
            mass = 0.85;
            stiffness = 420.0;
            damping = 30.0;
          }
        ])
      ];

      animation = [
        {
          enabled = true;
          leaf = "global";
          bezier = "appleFluid";
          speed = 3.5;
        }
        {
          enabled = true;
          leaf = "border";
          bezier = "appleSnappy";
          speed = 2.8;
        }
        {
          enabled = true;
          leaf = "windows";
          spring = "appleSpring";
          style = "popin 88%";
          speed = 3.6;
        }
        {
          enabled = true;
          leaf = "windowsIn";
          spring = "appleSnappySpring";
          style = "popin 86%";
          speed = 3.4;
        }
        {
          enabled = true;
          leaf = "windowsOut";
          bezier = "appleSheet";
          style = "popin 90%";
          speed = 2.2;
        }
        {
          enabled = true;
          leaf = "windowsMove";
          spring = "appleSpring";
          speed = 3.0;
        }
        {
          enabled = true;
          leaf = "layers";
          bezier = "appleDecel";
          style = "popin 94%";
          speed = 2.6;
        }
        {
          enabled = true;
          leaf = "layersIn";
          spring = "appleSnappySpring";
          style = "popin 94%";
          speed = 2.8;
        }
        {
          enabled = true;
          leaf = "layersOut";
          bezier = "appleSheet";
          style = "popin 94%";
          speed = 2.0;
        }
        {
          enabled = false;
          leaf = "fade";
        }
        {
          enabled = true;
          leaf = "workspaces";
          style = "slidevert";
          bezier = "appleFluid";
          speed = 3.4;
        }
        {
          enabled = true;
          leaf = "specialWorkspace";
          style = "slidevert";
          bezier = "appleSheet";
          speed = 3.2;
        }
      ];

      on =
        map (
          entry: let
            command =
              (
                if entry.useUwsm
                then "uwsm app -- "
                else ""
              )
              + entry.command;
          in
            mkArgs [
              "hyprland.start"
              (mkLuaFn ''hl.exec_cmd(${builtins.toJSON command})'')
            ]
        )
        config.desktop.compositor.autostart;

      layer_rule = map mapLayerRule config.desktop.layerRules;

      workspace_rule =
        [
          {
            workspace = "w[tv1]s[false]";
            gaps_in = config.desktop.compositor.margin.inner;
            gaps_out = config.desktop.compositor.margin.outer;
          }
          {
            workspace = "f[1]s[false]";
            gaps_in = config.desktop.compositor.margin.inner;
            gaps_out = config.desktop.compositor.margin.outer;
          }
        ]
        ++ (genList (
            index: let
              workspace = index + 1;
            in
              {
                workspace = toString workspace;
              }
              // lib.optionalAttrs (
                builtins.elem workspace config.desktop.compositor.workspaces.defaults
              ) {default = true;}
          )
          config.desktop.compositor.workspaces.count);

      window_rule = map mapWindowRule config.desktop.windowRules;
    };
  };
}
