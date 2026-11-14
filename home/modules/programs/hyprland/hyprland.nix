{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (builtins) concatLists genList;
  inherit (lib.generators) mkLuaInline;
  hypr = import ../../../lib/hyprland.nix {inherit config lib;};
  inherit (hypr) mkArgs mkDsp mkDspExec mkLuaFn mkTouchKeyboard;

  touchKeyboard = mkTouchKeyboard pkgs;
  touchCommands = {
    toggle-touch-keyboard = "pkill -SIGRTMIN wvkbd-mobintl || uwsm app -- ${touchKeyboard}";
    show-touch-keyboard = "pkill -USR2 wvkbd-mobintl || uwsm app -- ${touchKeyboard}";
    hide-touch-keyboard = "pkill -USR1 wvkbd-mobintl || true";
  };

  mapMatch = match:
    lib.filterAttrs (_: value: value != null) {
      class = match.appId;
      title = match.title;
      initial_title = match.initialTitle;
      xwayland = match.xwayland;
    };

  mapWindowRule = rule:
    {
      inherit (rule) name;
      match = mapMatch rule.match;
    }
    // lib.filterAttrs (_: value: value) {
      float = rule.float;
      center = rule.center;
      opaque = rule.opaque;
      pin = rule.pin;
      persistent_size = rule.persistentSize;
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
        namespace = rule.namespace;
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
          if !(lib.elem pkgs.hyprland.version [ "0.57.0" "0.57.1" "0.57.2" ])
          then throw "hyprgrass has no pin for Hyprland ${pkgs.hyprland.version}; update pkgs/hyprland-plugins/hyprgrass.nix"
          else [pkgs.hyprlandPlugins.hyprgrass]
        else []
      );

    settings = {
      colors = {
        _var = mkLuaInline ''          (function()
                    local function to_argb(c, alpha)
                      local hex = type(c) == "string" and c:match("(%x%x%x%x%x%x)") or "000000"
                      return tonumber((alpha or "ff") .. hex, 16)
                    end
                    local ok, m = pcall(require, "noctalia")
                    if ok and type(m) == "table" and type(m.colors) == "table" then
                      if type(m.apply_theme) == "function" then m.apply_theme() end
                      return {
                        active_border = m.colors.primary,
                        inactive_border = m.colors.surface,
                        active_shadow = m.colors.surface,
                        inactive_shadow = m.colors.surface,
                        bg_color = to_argb(m.colors.surface, "ff"),
                        label_color = to_argb(m.colors.on_surface, "ff"),
                        label_background = to_argb(m.colors.surface, "cc"),
                      }
                    end
                    return {
                      active_border = "rgba(ffffffff)",
                      inactive_border = "rgba(ffffff88)",
                      active_shadow = "rgba(000000ee)",
                      inactive_shadow = "rgba(000000aa)",
                      bg_color = 0xff000000,
                      label_color = 0xffffffff,
                      label_background = 0xcc000000,
                    }
                  end)()'';
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
              cm = "hdr";
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

          inactive_opacity = 0.7;
          active_opacity = 0.85;

          shadow = {
            enabled = true;
            color = mkLuaInline "colors.active_shadow";
            color_inactive = mkLuaInline "colors.inactive_shadow";
          };

          blur = {
            enabled = true;
            size = 3;
            passes = 2;
            noise = 0.015;
            ignore_opacity = true;
            vibrancy_darkness = 0.0;
            contrast = 0.95;
            brightness = 0.85;
            vibrancy = 0.25;
            new_optimizations = true;
            xray = true;
            popups = true;
            popups_ignorealpha = 0.2;
          };

          motion_blur = {
            enabled = true;
          };

          wobble = {
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

    # Guard plugin-specific Lua configuration so an unloaded or paused plugin
    # cannot abort hyprland.lua before submaps and later rules are registered.
    extraConfig = ''
      if hl.plugin.hyprglass then
        hl.plugin.hyprglass.config({
          blur_strength = 0.5,
          blur_iterations = 3,
          lens_distortion = 1,
          refraction_strength = 2,
          chromatic_aberration = 0.9,
          fresnel_strength = 1,
          specular_strength = 1,
          xray = true,
          layers = { enabled = false },
          dark = { brightness = 1, adaptive_dim = 0.05 },
          light = { brightness = 1, adaptive_boost = 0.05 },
        })
      end

      if hl.plugin.hyprtasking then
        hl.config({
          plugin = {
            hyprtasking = {
              layout = "linear",
              bg_color = colors.bg_color,
              gap_size = ${toString config.desktop.compositor.margin.inner},
              border_size = 2,
              exit_on_hovered = false,
              warp_on_move_window = 1,
              close_overview_on_reload = false,
              jump = {
                enabled = false,
                label_color = colors.label_color,
                label_background = colors.label_background,
              },
              gestures = {
                enabled = true,
                -- Disable 3-finger overview swipes so Hyprland's native 3-finger gestures remain intact.
                move_fingers = 0,
                open_fingers = 4,
                open_distance = 300,
                open_positive = true,
              },
              linear = {
                top = false,
                height = 300,
                scroll_speed = 1.0,
                blur = false,
              },
            },
          },
        })
      end
    '';
  };
}
