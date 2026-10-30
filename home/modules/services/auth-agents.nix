{ pkgs, ... }:
{
  services.gnome-keyring = {
    enable = true;
    components = [ "secrets" ];
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    defaultCacheTtl = 28800;
    maxCacheTtl = 86400;
    extraConfig = "allow-loopback-pinentry";
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

  home.sessionVariablesExtra = ''
    if [ -z "$SSH_CONNECTION" ]; then
      export SSH_AUTH_SOCK="''${XDG_RUNTIME_DIR}/rbw/ssh-agent-socket"
    fi
  '';

  systemd.user.services.rbw-agent = {
    Unit.Description = "rbw SSH agent";
    Service = {
      Type = "forking";
      PIDFile = "%t/rbw/pidfile";
      ExecStart = "${pkgs.rbw}/bin/rbw-agent";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
