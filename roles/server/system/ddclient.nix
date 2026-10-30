{ config, ... }:

let
  domains = import ./domains.nix;
in
{
  services.ddclient = {
    enable = true;
    protocol = "duckdns";
    passwordFile = "/run/credentials/ddclient.service/duckdns";
    domains = [ domains.base ];
  };

  systemd.services.ddclient.serviceConfig.LoadCredential = [
    "duckdns=${config.sops.secrets."duckdns_password".path}"
  ];

  sops.secrets."duckdns_password" = {
    restartUnits = [ "ddclient.service" ];
  };
}
