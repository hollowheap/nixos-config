{ config, ... }:

let
  baseDomain = "hollowheap.duckdns.org";
  headscaleDomain = "headscale.${baseDomain}";
  meshDomain = "mesh.${baseDomain}";
in
{
  networking.hosts = {
    "127.0.0.1" = [
      baseDomain
      headscaleDomain
    ];
  };

  services = {
    resolved = {
      enable = true;
      settings = {
        Resolve = {
          DNS = [
            "1.1.1.2#security.cloudflare-dns.com"
            "1.0.0.2#security.cloudflare-dns.com"
            "2606:4700:4700::1112#security.cloudflare-dns.com"
            "2606:4700:4700::1002#security.cloudflare-dns.com"
          ];
          DNSOverTLS = true;
        };
      };
    };

    ddclient = {
      enable = true;
      usev4 = "webv4, webv4=ipify-ipv4";
      protocol = "duckdns";
      passwordFile = config.sops.secrets."duckdns_password".path;
      domains = [ baseDomain ];
    };

    headscale = {
      enable = true;
      settings = {
        dns = {
          base_domain = meshDomain;
          nameservers.global = [
            "1.1.1.2"
            "1.0.0.2"
          ];
        };
      };
    };

    tailscale.enable = true;

    caddy = {
      enable = true;
      virtualHosts."${headscaleDomain}" = {
        extraConfig = ''
          reverse_proxy http://127.0.0.1:8080
        '';
      };
    };
  };
}
