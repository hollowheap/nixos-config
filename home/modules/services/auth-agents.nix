{ pkgs, ... }:
{
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry = {
      package = pkgs.pinentry-qt;
      program = "pinentry-qt";
    };
  };

  programs.rbw = {
    enable = true;
    settings = {
      email = "yuckychong@gmail.com";
      base_url = "https://vault.mesh.hollowheap.duckdns.org";
      lock_timeout = 86400;
      pinentry = pkgs.pinentry-qt;
    };
  };

  home.packages = [
    pkgs.pinentry-qt
  ];
}
