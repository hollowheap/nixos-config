{
  pkgs,
  config,
  ...
}:

{
  programs = {

    uwsm.enable = true;

    # Window Managers
    hyprland = {
      enable = true;
      package = pkgs.unstable.hyprland;
      withUWSM = true;
    };
  };

  services.displayManager.noctalia-greeter = {
    enable = true;
    passwordless-sync-users = config.users.adminUsers;
    settings = {
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 20;
        path = "${pkgs.bibata-cursors}/share/icons";
      };
      keyboard.layout = "us";

      output = {
        scale = 1;
      };
    };
  };
}
