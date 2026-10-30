{
  pkgs,
  config,
  ...
}:

{
  imports = [ ./services.nix ];

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
      };

      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 20;
        path = "${pkgs.bibata-cursors}/share/icons";
      };

      keyboard.layout = config.desktop.input.layout;

      output = {
        scales = "eDP-1:${toString config.desktop.primaryScale}";
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
