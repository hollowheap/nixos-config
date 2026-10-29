{ config, pkgs, ... }:

let
  domains = import ./domains.nix;
in
{
  networking = {
    hosts = {
      "127.0.0.1" = [
        domains.base
      ];
    };
    firewall.allowedTCPPorts = [
      80
      443
    ];
  };

  # Deterministic local CA for loopback-only vhosts
  security.pki.certificateFiles = [
    ../../../certs/local-ca.crt
  ];

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/duckdns@v0.5.0" ];
      hash = "sha256-hdJoUoWpDZEz367Rwhagz5040TMHBReLY+hhHjMfwgM=";
    };
    environmentFile = config.sops.templates."caddy_env".path;
    virtualHosts."${domains.base}" = {
      extraConfig = ''
        tls {
          dns duckdns {env.DUCKDNS_API_TOKEN}
        }
        respond 204
      '';
    };
  };

  sops.secrets."caddy_tls_key" = {
    owner = "caddy";
    mode = "0400";
    restartUnits = [ "caddy.service" ];
  };

  sops.templates."caddy_env" = {
    content = ''DUCKDNS_API_TOKEN=${config.sops.placeholder."duckdns_password"}'';
    owner = "caddy";
    mode = "0400";
    restartUnits = [ "caddy.service" ];
  };
}
