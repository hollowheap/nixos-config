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
    firewall = {
      allowedTCPPorts = [ ];
      interfaces.tailscale0.allowedTCPPorts = [ 443 ];
      interfaces.lo.allowedTCPPorts = [ 443 ];
    };
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = [ "github.com/caddy-dns/duckdns@v0.5.0" ];
      hash = "sha256-hdJoUoWpDZEz367Rwhagz5040TMHBReLY+hhHjMfwgM=";
    };
    environmentFile = config.sops.templates."caddy_env".path;
    enableReload = false;
    globalConfig = "admin off\ngrace_period 10s";
    email = "admin@example.com";
    virtualHosts."${domains.base}" = {
      extraConfig = ''
        tls {
          dns duckdns {env.DUCKDNS_API_TOKEN}
        }
        respond 204
      '';
    };
  };

  sops.templates."caddy_env" = {
    content = ''DUCKDNS_API_TOKEN=${config.sops.placeholder."duckdns_password"}'';
    owner = "caddy";
    mode = "0400";
    restartUnits = [ "caddy.service" ];
  };
}
