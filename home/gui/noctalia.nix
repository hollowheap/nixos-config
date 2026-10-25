{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.noctalia.enable = true;
  programs.noctalia.settings = {
    theme = {
      mode = lib.mkForce "dark";
      source = lib.mkForce "wallpaper";
      wallpaper_scheme = "faithful";
      pure_black_dark = true;
      templates = {
        builtin_ids = [ ];
        community_ids = [
          "discord"
          "steam"
        ];

        user = {
          hyprland = {
            enabled = true;
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/hypr-colors.lua";
            output_path = "$XDG_CONFIG_HOME/hypr/noctalia.lua";
            post_hook = "hyprctl reload config-only";
          };

          # Noctalia has no native wallpaper-change hook, so a dummy template
          # carries the post_hook that regenerates the wallust CLI palette.
          wallust = {
            enabled = true;
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/wallust.dummy";
            output_path = "$XDG_CACHE_HOME/noctalia/wallust.dummy";
            post_hook = ''
              st="${config.home.homeDirectory}/.local/state/noctalia/settings.toml"
              if [ -r "$st" ]; then
                img="$(${pkgs.gawk}/bin/awk -F'=' '
                  /^\[wallpaper(\.last)?\]/ { in_sec = 1; next }
                  /^\[/ { in_sec = 0 }
                  in_sec && /^[[:space:]]*path[[:space:]]*=/ {
                    gsub(/^[[:space:]]*path[[:space:]]*=[[:space:]]*["\047]?|["\047]?[[:space:]]*$/, "")
                    print
                    exit
                  }
                ' "$st" 2>/dev/null || true)"
                if [ -n "$img" ] && [ -f "$img" ] && [ -r "$img" ]; then
                  ${pkgs.wallust}/bin/wallust run "$img" -s
                fi
              fi
            '';
          };

          gtk = {
            enabled = true;
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/gtk-accent.css";
            output_path = "$XDG_CACHE_HOME/noctalia/gtk-accent.css";
            post_hook = "${pkgs.mactahoe-gtk-accent}/bin/mactahoe-gtk-accent";
          };

          dconf_theme = {
            enabled = true;
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/dconf-theme.txt";
            output_path = "$XDG_CACHE_HOME/noctalia/dconf-theme.txt";
            post_hook = "${pkgs.mactahoe-icon-accent}/bin/mactahoe-icon-accent --apply";
          };

          openrgb = {
            enabled = true;
            input_path = "$XDG_CONFIG_HOME/noctalia/templates/openrgb.color";
            output_path = "$XDG_CACHE_HOME/noctalia/openrgb.color";
            post_hook = ''
              if [ -f "$XDG_CACHE_HOME/noctalia/openrgb.color" ]; then
                c="$(${pkgs.coreutils}/bin/cat "$XDG_CACHE_HOME/noctalia/openrgb.color" | ${pkgs.gnused}/bin/sed 's/#//' | ${pkgs.coreutils}/bin/tr -d ' \n')"
                if [ -n "$c" ]; then
                  ${pkgs.openrgb-with-all-plugins}/bin/openrgb --noautoconnect --client 127.0.0.1:6742 -m static -c "$c" || \
                  ${pkgs.openrgb-with-all-plugins}/bin/openrgb --noautoconnect --client 127.0.0.1:6742 -c "$c" || true
                fi
              fi
            '';
          };
        };
      };
    };

    shell = {
      setup_wizard_enabled = false;
      polkit_agent = true;
      launch_apps_custom_command = "uwsm app -- $CMD";
      greeter_sync.auto_sync = true;

      button_borders = false;
      input_borders = false;
      popup_borders = false;
      card_borders = false;

      screen_corners = {
        enabled = true;
        size = config.styles.dims.border.radius * 2;
      };
      panel = {
        transparency_mode = "glass";
        borders = false;
      };
      screenshot = {
        directory = "~/Pictures/Screenshots";
        freeze_screen = true;
        pipe_to_command = true;
        pipe_command = "satty -f - --copy-command wl-copy";
      };

      launcher.app_grid = true;
      session.grid = true;
    };
    location.address = "Singapore, SG";
    calendar.enabled = true;
    calendar.account.personal = {
      type = "google";
      name = "Personal";
    };
    brightness = {
      enable_ddcutil = true;
      monitor.HDMI-A-1.backend = "ddcutil";
      monitor.DP-1.backend = "ddcutil";
    };
    weather.enabled = true;
    wallpaper.transition_on_startup = true;
    dock = {
      enabled = true;
      auto_hide = false;
      smart_auto_hide = true;
      icon_size = 24;
      reserve_space = false;
    };
    bar.order = [ "main" ];
    bar."main" = {
      position = "top";
      padding = 24;
      auto_hide = false;
      smart_auto_hide = true;
      margin_ends = 750;
      margin_edge = 0;
      reserve_space = false;
      concave_edge_corners = true;
      background_opacity = 0.9;
      start = [
        "group:media"
      ];
      center = [ "workspaces" ];
      end = [ "group:actions" ];
      capsule_group = [
        {
          id = "media";
          accordion = true;
          members = [
            "media"
            "audio_visualizer"
            "clock"
          ];
        }
        {
          id = "actions";
          accordion = true;
          accordion_direction = "start";
          members = [
            "battery"
            "weather"
            "network"
            "bluetooth"
            "volume"
            "notifications"
            "tray"
          ];
        }
      ];
    };

    battery.warning_threshold = 10;

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
        output = "HDMI-A-1";

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
        capsule = true;
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

  home.packages = with pkgs; [
    ddcutil
    satty
    wl-clipboard
    openrgb-with-all-plugins
    mactahoe-icon-accent
    mactahoe-gtk-accent
  ];

  xdg.configFile."noctalia/templates/wallust.dummy".text = "dummy";
  xdg.configFile."noctalia/templates/openrgb.color".text =
    "{{ colors.primary.default.hex_stripped }}";
  xdg.configFile."noctalia/templates/gtk-accent.css".source =
    ../../assets/noctalia-templates/gtk-accent.css;
  xdg.configFile."noctalia/templates/dconf-theme.txt".text =
    "{{ colors.primary.default.hex }} dark";
}
