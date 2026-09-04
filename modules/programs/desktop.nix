{ pkgs, lib, ... }:

{
  programs = {
    noctalia-greeter.enable = true;
    noctalia-greeter.settings = {
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 20;
        path = "${pkgs.bibata-cursors}/share/icons";
      };
      keyboard.layout = "us";
    };

    uwsm.enable = true;

    # Window Managers
    hyprland.enable = true;
    hyprland.package = pkgs.unstable.hyprland;
    hyprland.withUWSM = true;
    niri.enable = true;
    river-classic.enable = true;
    river-classic.extraPackages = lib.mkForce [ ];
  };
}
