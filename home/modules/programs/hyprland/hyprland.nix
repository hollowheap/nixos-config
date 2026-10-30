{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) concatLists genList;
  inherit (lib.generators) mkLuaInline;
  hypr = import ../../../lib/hyprland.nix { inherit config lib; };
  inherit (hypr) mkArgs mkDsp mkDspExec mkLuaFn;

  touchKeyboard = "${pkgs.wvkbd-split}/bin/wvkbd-mobintl --landscape-layers landscape,landscapespecial --bg 00000000 -R 8 -L 280";
  touchCommands = {
    toggle-touch-keyboard = "pkill -SIGRTMIN wvkbd-mobintl || uwsm app -- ${touchKeyboard}";
    show-touch-keyboard = "pkill -USR2 wvkbd-mobintl || uwsm app -- ${touchKeyboard}";
    hide-touch-keyboard = "pkill -USR1 wvkbd-mobintl || true";
  };

  mapMatch =
    match:
    lib.filterAttrs (_: value: value != null) {
      class = match.appId;
      title = match.title;
      initial_title = match.initialTitle;
      xwayland = match.xwayland;
    };

  mapWindowRule =
    rule:
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
    // lib.optionalAttrs (rule.size != [ ]) { inherit (rule) size; }
    // lib.optionalAttrs (rule.content != null) { inherit (rule) content; }
    // lib.optionalAttrs (rule.suppressEvent != null) {
      suppress_event = rule.suppressEvent;
    };

  mapLayerRule =
    rule:
    {
      inherit (rule) name;
      match = {
        namespace = rule.namespace;
      };
    }
    // lib.optionalAttrs rule.noAnim { no_anim = true; }
    // lib.optionalAttrs rule.blur { blur = true; }
    // lib.optionalAttrs rule.blurPopups { blur_popups = true; }
    // lib.optionalAttrs (rule.ignoreAlpha != null) {
      ignore_alpha = rule.ignoreAlpha;
    };
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
    ++ (if config.desktop.touch then
         if pkgs.hyprland.version != "0.56.2" then
           throw "hyprgrass pin targets Hyprland 0.56.2; update pkgs/hyprland-plugins/hyprgrass.nix"
         else
           [ hyprgrass ]
       else
         [ ]);

    settings = {
      colors = {
        _var = mkLuaInline ''(function()
          local ok, m = pcall(require, "noctalia")
          if ok and type(m) == "table" then return m end
          return {
            active_border = "rgba(ffffffff)",
            inactive_border = "rgba(ffffff88)",
            active_shadow = "rgba(000000ee)",
            inactive_shadow = "rgba(000000aa)",
          }
        end)()'';
      };

      "plugin.hyprgrass.gesture" = lib.mkIf config.desktop.touch (
        map (
          gesture:
          {
            inherit (gesture) pattern;
            action =
              if builtins.isString gesture.action && touchCommands ? ${gesture.action} then
                mkLuaFn ''hl.dispatch(hl.dsp.exec_cmd(${builtins.toJSON touchCommands.${gesture.action}}))''
              else if builtins.isString gesture.action && config.desktop.actions ? ${gesture.action} then
                mkLuaFn ''hl.dispatch(hl.dsp.exec_cmd(${builtins.toJSON config.desktop.actions.${gesture.action}.command}))''
              else if builtins.isAttrs gesture.action then
                mkLuaFn ''hl.dispatch(hl.dsp.exec_cmd(${builtins.toJSON gesture.action.exec}))''
              else
                gesture.action;
          }
        ) config.desktop.touchscreen.gestures
      );

      "plugin.hyprgrass.bind" = lib.mkIf config.desktop.touch (
        map (
          bind:
          {
            inherit (bind) pattern;
            action =
              if builtins.isString bind.action && touchCommands ? ${bind.action} then
                mkDspExec touchCommands.${bind.action}
              else if builtins.isString bind.action && config.desktop.actions ? ${bind.action} then
                mkDspExec config.desktop.actions.${bind.action}.command
              else if builtins.isAttrs bind.action && bind.action ? exec then
                mkDspExec bind.action.exec
              else
                mkDsp bind.action.dispatcher;
          }
          // lib.optionalAttrs (bind ? mouse) { inherit (bind) mouse; }
        ) config.desktop.touchscreen.binds
      );

      monitor = map (
        monitor:
        let
          configured = lib.filterAttrs (_: value: value != null) monitor;
          hdr = config.desktop.hdr && configured.output == config.desktop.primaryOutput;
        in
        (if configured.output == config.desktop.primaryOutput then
          configured // { scale = config.desktop.primaryScale; }
        else
          configured)
        // lib.optionalAttrs hdr {
          cm = "hdr";
          supports_hdr = 1;
        }
      ) config.desktop.monitors;

      device = map (
        device:
        {
          inherit (device) name;
          output = if device.output == null then config.desktop.touchscreen.output else device.output;
        }
      ) config.desktop.touchscreen.devices;

      gesture = lib.mkIf config.desktop.touch [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
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
          workspace_swipe_touch = true;
          workspace_swipe_cancel_ratio = 0.15;
          workspace_swipe_invert = false;
        };

        general = {
          layout = "scrolling";

          resize_on_border = true;

          border_size = 0;
          col = {
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
            new_optimizations = true;
            xray = true;
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
          allow_session_lock_restore = true;
          session_lock_xray = true;
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

      on = map (
        entry:
        let
          command = (if entry.useUwsm then "uwsm app -- " else "") + entry.command;
        in
        mkArgs [
          "hyprland.start"
          (mkLuaFn ''hl.exec_cmd(${builtins.toJSON command})'')
        ]
      ) config.desktop.compositor.autostart;

      layer_rule = map mapLayerRule config.desktop.layerRules;

      workspace_rule = [
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
         index:
         let
           workspace = index + 1;
         in
         {
           workspace = toString workspace;
         }
         // lib.optionalAttrs (
           builtins.elem workspace config.desktop.compositor.workspaces.defaults
         ) { default = true; }
       ) config.desktop.compositor.workspaces.count);

      window_rule = map mapWindowRule config.desktop.windowRules;

    };
  };
}
