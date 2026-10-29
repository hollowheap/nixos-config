{ config, ... }:

let
  domains = import ./domains.nix;
in
{
  services.ddclient = {
    enable = true;
    usev4 = "webv4, webv4=ipify-ipv4";
    protocol = "duckdns";
    passwordFile = config.sops.secrets."duckdns_password".path;
    domains = [ domains.base ];
  };

  sops.secrets."duckdns_password" = {
    restartUnits = [ "ddclient.service" ];
  };
}
