{
  pkgs,
  config,
  ...
}: {
  imports = [./services.nix];

  programs = {
    uwsm.enable = true;

    # Window Managers
    hyprland = {
      enable = true;
      package = pkgs.unstable.hyprland;
      withUWSM = true;
    };
  };

  environment.sessionVariables = {
    UWSM_SILENT_START = "2";
  };

  services.displayManager.noctalia-greeter = {
    enable = true;
    passwordless-sync-users = config.users.adminUsers;
    settings = {
      appearance = {
        hide_logo = true;
        font_family = config.desktop.fonts.sansSerif;
      };

      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 20;
        path = "${pkgs.bibata-cursors}/share/icons";
      };

      keyboard = {
        layout = config.desktop.input.layout;
        variant = config.desktop.input.variant;
        options = config.desktop.input.options;
      };

      output = {
        name = config.desktop.primaryOutput;
        scales = "${config.desktop.primaryOutput}:${toString config.desktop.primaryScale}";
      };

      session = {
        default = "Hyprland (uwsm-managed)";
      };

      idle = {
        timeout = 300;
      };
    };
  };
}
