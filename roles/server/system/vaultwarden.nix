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
    environmentFile = config.sops.secrets."vaultwarden_env".path;
    config = {
      DOMAIN = "https://${domains.vaultMesh}";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = true;
      SIGNUPS_DOMAINS_WHITELIST = "gmail.com";
    };
  };

  services.caddy.virtualHosts."${domains.vaultMesh}" = {
    extraConfig = ''
      tls ${../../../certs/local-leaf.crt} ${config.sops.secrets."caddy_tls_key".path}
      reverse_proxy 127.0.0.1:8222
    '';
  };

  sops.secrets."vaultwarden_env" = {
    owner = "vaultwarden";
    mode = "0400";
    restartUnits = [ "vaultwarden.service" ];
  };
}
