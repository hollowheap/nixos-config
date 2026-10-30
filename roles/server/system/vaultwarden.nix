{ config, ... }:

let
  domains = import ./domains.nix;
in
{
  networking.hosts = {
    "127.0.0.1" = [
      domains.vaultMesh
    ];
  };

  services.vaultwarden = {
    enable = true;
    backupDir = "/var/backup/vaultwarden";
    environmentFile = config.sops.secrets."vaultwarden_env".path;
    config = {
      DOMAIN = "https://${domains.vaultMesh}";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
      SIGNUPS_DOMAINS_WHITELIST = "gmail.com";
      IP_HEADER = "X-Forwarded-For";
      SENDS_ALLOWED = false;
    };
  };

  services.caddy.virtualHosts."${domains.vaultMesh}" = {
    logFormat = "level INFO";
    extraConfig = ''
      tls internal
      reverse_proxy 127.0.0.1:8222
    '';
  };

  sops.secrets."vaultwarden_env" = {
    owner = "vaultwarden";
    mode = "0400";
    restartUnits = [ "vaultwarden.service" ];
  };
}
