{ pkgs, ... }:
{
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    pinentry = {
      package = pkgs.pinentry-gnome3;
      program = "pinentry-gnome3";
    };
  };

  programs.rbw = {
    enable = true;
    settings = {
      email = "yuckychong@gmail.com";
      base_url = "https://vault.mesh.hollowheap.duckdns.org";
      lock_timeout = 86400;
      pinentry = pkgs.pinentry-gnome3;
    };
  };

  home.packages = [
    pkgs.gcr_3
    pkgs.pinentry-gnome3
  ];
}
