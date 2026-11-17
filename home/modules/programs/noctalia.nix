{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      nightlight = {
        enabled = false;
      };

      hooks = {
        started = "${pkgs.writeShellScript "noctalia-started-hook" ''
          if [ -n "$NOCTALIA_WALLPAPER_PATH" ] && [ -f "$NOCTALIA_WALLPAPER_PATH" ]; then
            ${pkgs.wallust-palette}/bin/wallust-palette --image "$NOCTALIA_WALLPAPER_PATH" --templates-dir "${config.xdg.userDirs.templates}" --apply
          fi
        ''}";
        wallpaper_changed = "${pkgs.callPackage ../../../pkgs/noctalia-wallpaper-hook.nix {
          templatesDir = config.xdg.userDirs.templates;
        }}";
      };

      theme = {
        mode = lib.mkForce "dark";
        source = lib.mkForce "wallpaper";
        wallpaper_scheme = "faithful";
        pure_black_dark = true;
        templates = {
          builtin_ids = ["hyprland"];
          community_ids = [
            "discord"
            "steam"
            "thunderbird"
            "libreoffice"
            "telegram"
          ];
        };
      };

      plugins = {
        enabled = ["bagusk99/super-caffeine"];
      };

      shell = {
        font_family = config.styles.fonts.sansSerif.name;
        setup_wizard_enabled = false;
        polkit_agent = true;
        launch_apps_custom_command = "uwsm app -- $CMD";
        greeter_sync.auto_sync = true;

        corner_radius_scale = 0.95;
        password_style = "random";

        button_borders = false;
        input_borders = false;
        popup_borders = false;
        card_borders = false;

        launcher = {
          category_icon_only = true;
          app_grid = true;
          width = 595;

          providers.session.global = true;
        };
        panel = {
          transparency_mode = "glass";
          borders = false;
          shadow = false;
          floating_offset = 6;
          control_center_placement = "attached";
          control_center_position = "top_center";
          launcher_placement = "attached";
          launcher_position = "top_center";
          session_placement = "attached";
          session_position = "top_center";
          wallpaper_placement = "attached";
          wallpaper_position = "top_center";
        };
        screen_corners = {
          enabled = true;
          size = config.desktop.compositor.rounding.radius;
        };
        screenshot = {
          directory = "~/Pictures/Screenshots";
          freeze_screen = true;
          pipe_to_command = true;
          pipe_command = "satty -f - --copy-command wl-copy";
        };
        session.grid = true;
        shadow.alpha = 0.25;
        window_switcher.mru = true;
      };
      location.address = "Singapore, SG";
      control_center.width = 700;
      control_center.shortcuts = [
        {type = "wifi";}
        {type = "bluetooth";}
        {type = "bagusk99/super-caffeine:super-caffeine-toggle";}
        {type = "nightlight";}
        {type = "notification";}
        {type = "power_profile";}
      ];
      calendar.enabled = true;
      calendar.account.personal = {
        type = "google";
        name = "Personal";
      };
      brightness.enable_ddcutil = false;
      weather.enabled = true;
      wallpaper.transition_on_startup = true;
      dock = {
        enabled = true;
        auto_hide = false;
        smart_auto_hide = true;
        icon_size = 24;
        reserve_space = false;
        background_opacity = 0.55;
        shadow = false;
      };
      bar.order = ["main"];
      bar."main" = {
        position = "top";
        padding = 14;
        thickness = 40;
        auto_hide = false;
        smart_auto_hide = true;
        margin_ends = 826;
        margin_edge = 0;
        panel_overlap = 3;
        reserve_space = false;
        concave_edge_corners = true;
        radius = 20;
        background_opacity = 0.55;
        capsule = true;
        capsule_opacity = 0.22;
        compositor_blur = true;
        border_width = 0;
        capsule_border_width = 0;
        shadow = true;
        capsule_radius = 14;
        start = [
          "clock"
          "group:media"
        ];
        center = ["workspaces"];
        end = ["group:actions"];
        capsule_group = [
          {
            id = "media";
            members = [
              "media"
              "audio_visualizer"
            ];
          }
          {
            id = "actions";
            accordion = true;
            accordion_direction = "start";
            members = [
              "battery"
              "weather"
              "volume"
              "notifications"
              "tray"
            ];
          }
        ];
      };

      battery.warning_threshold = 10;

      notification = {
        border = false;
        background_opacity = 0.55;
      };

      osd = {
        background_opacity = 0.55;
        border = false;
        border_width = 0;
      };

      idle.behavior = {
        lock = {
          enabled = true;
          timeout = 600;
          action = "lock";
        };

        screen-off = {
          enabled = true;
          timeout = 660;
          action = "screen_off";
        };

        suspend = {
          enabled = false;
          timeout = 900;
          action = "lock_and_suspend";
        };
      };

      lockscreen_widgets = {
        enabled = true;

        clock-1 = {
          output = config.desktop.primaryOutput;
        };
      };

      widget = {
        media = {
          album_art_only = true;
        };
        audio_visualizer = {
          bands = 8;
          show_when_idle = true;
        };
        workspaces = {
          labels_only_when_occupied = true;
        };
        weather = {
          show_condition = false;
          show_temperature = true;
        };
        battery = {
          display_mode = "graphic";
          show_label = true;
        };
        network = {
          show_label = false;
        };
        tray = {
          anchor = true;
          drawer = true;
        };
      };
    };
  };
  desktop = {
    # Shell-backed actions. Replace this block when changing desktop shells;
    # keybinds and gestures refer only to the neutral names.
    layerRules = [
      {
        name = "noctalia";
        namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$";
        noAnim = true;
        blur = true;
        blurPopups = true;
        ignoreAlpha = 0.15;
      }
    ];

    windowRules = [
      {
        name = "noctalia-settings";
        match.appId = "dev.noctalia.Noctalia";
        match.initialTitle = "Noctalia Settings";
        float = true;
        center = true;
        size = [
          "monitor_w*0.7"
          "monitor_h*0.8"
        ];
      }
    ];

    actions = {
      clipboard.command = "noctalia msg panel-toggle clipboard";
      launcher.command = "noctalia msg panel-toggle launcher";
      window-switcher.command = "noctalia msg window-switcher";
      session.command = "noctalia msg panel-toggle session";
      lock.command = "noctalia msg session lock";
      brightness-up.command = "noctalia msg brightness-up";
      brightness-down.command = "noctalia msg brightness-down";
      volume-up.command = "noctalia msg volume-up";
      volume-down.command = "noctalia msg volume-down";
      volume-mute.command = "noctalia msg volume-mute";
      media-toggle.command = "noctalia msg media toggle";
      media-next.command = "noctalia msg media next";
      media-previous.command = "noctalia msg media previous";
      screenshot-region.command = "noctalia msg screenshot-region";
      screenshot-fullscreen.command = "noctalia msg screenshot-fullscreen";
      screenshot-annotate.command = "noctalia msg screenshot-annotate";
    };
  };

  home.packages = with pkgs; [
    ddcutil
    satty
    wl-clipboard
    openrgb-with-all-plugins
    mactahoe-icon-accent
    mactahoe-gtk-accent
  ];
}
