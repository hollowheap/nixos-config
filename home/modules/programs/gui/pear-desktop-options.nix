{
  lib,
  ...
}:
let
  inherit (lib) mkOption;
  inherit (lib.types) attrsOf bool enum listOf str submodule unspecified;
in
{
  options.programs.pear-desktop = {
    enable = mkOption {
      type = bool;
      default = true;
      description = "Enable declarative Pear Desktop configuration.";
    };

    settings = mkOption {
      type = submodule {
        options = {
          options = mkOption {
            type = submodule {
              freeformType = attrsOf unspecified;
              options = {
                tray = mkOption {
                  type = bool;
                  default = true;
                  description = "Show a system tray icon and hide the window on close instead of quitting.";
                };
                appVisible = mkOption {
                  type = bool;
                  default = true;
                  description = "Show the application window.";
                };
                autoUpdates = mkOption {
                  type = bool;
                  default = true;
                  description = "Check for application updates.";
                };
                alwaysOnTop = mkOption {
                  type = bool;
                  default = false;
                  description = "Keep the window above other windows.";
                };
                hideMenu = mkOption {
                  type = bool;
                  default = false;
                  description = "Hide the application menu bar.";
                };
                hideMenuWarned = mkOption {
                  type = bool;
                  default = false;
                  description = "Whether the hide-menu warning has been shown.";
                };
                startAtLogin = mkOption {
                  type = bool;
                  default = false;
                  description = "Start Pear Desktop at login.";
                };
                disableHardwareAcceleration = mkOption {
                  type = bool;
                  default = false;
                  description = "Disable Electron hardware acceleration.";
                };
                removeUpgradeButton = mkOption {
                  type = bool;
                  default = false;
                  description = "Remove the upgrade button from the UI.";
                };
                restartOnConfigChanges = mkOption {
                  type = bool;
                  default = false;
                  description = "Restart the application when settings change.";
                };
                trayClickPlayPause = mkOption {
                  type = bool;
                  default = false;
                  description = "Toggle playback when the tray icon is clicked.";
                };
                autoResetAppCache = mkOption {
                  type = bool;
                  default = false;
                  description = "Reset the application cache on startup.";
                };
                resumeOnStart = mkOption {
                  type = bool;
                  default = true;
                  description = "Resume the last played URL on startup.";
                };
                likeButtons = mkOption {
                  type = enum [
                    ""
                    "force"
                    "hide"
                  ];
                  default = "";
                  description = "Control the like/dislike buttons.";
                };
                swapLikeButtonsOrder = mkOption {
                  type = bool;
                  default = false;
                  description = "Swap the like and dislike button order.";
                };
                proxy = mkOption {
                  type = str;
                  default = "";
                  description = "Proxy URL used by the application.";
                };
                startingPage = mkOption {
                  type = str;
                  default = "";
                  description = "Page shown on startup.";
                };
                overrideUserAgent = mkOption {
                  type = bool;
                  default = false;
                  description = "Override the browser user agent.";
                };
                usePodcastParticipantAsArtist = mkOption {
                  type = bool;
                  default = false;
                  description = "Use podcast participants as track artists.";
                };
                themes = mkOption {
                  type = listOf str;
                  default = [ ];
                  description = "Extra CSS theme files applied to the UI.";
                };
              };
            };
            default = { };
            description = "General application options.";
          };

          plugins = mkOption {
            type = submodule {
              freeformType = attrsOf unspecified;
              options = {
                notifications = mkOption {
                  type = attrsOf unspecified;
                  default = { };
                  description = "Desktop notification plugin configuration.";
                };
                "video-toggle" = mkOption {
                  type = submodule {
                    freeformType = attrsOf unspecified;
                    options.mode = mkOption {
                      type = str;
                      default = "custom";
                      description = "Video toggle button mode.";
                    };
                  };
                  default = { };
                  description = "Video toggle plugin configuration.";
                };
                "precise-volume" = mkOption {
                  type = submodule {
                    freeformType = attrsOf unspecified;
                    options.globalShortcuts = mkOption {
                      type = attrsOf unspecified;
                      default = { };
                      description = "Global volume shortcut bindings.";
                    };
                  };
                  default = { };
                  description = "Precise volume plugin configuration.";
                };
                discord = mkOption {
                  type = submodule {
                    freeformType = attrsOf unspecified;
                    options.listenAlong = mkOption {
                      type = bool;
                      default = true;
                      description = "Enable Discord listen-along.";
                    };
                  };
                  default = { };
                  description = "Discord rich presence plugin configuration.";
                };
              };
            };
            default = { };
            description = "Plugin configuration keyed by plugin name.";
          };
        };
      };
      default = { };
      description = "Declarative Pear Desktop options and plugin settings. Runtime state (URL, window geometry) is preserved.";
    };
  };
}
