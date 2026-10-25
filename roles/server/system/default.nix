{ config, pkgs, ... }:

let
  baseDomain = "hollowheap.duckdns.org";
  headscaleDomain = "headscale.${baseDomain}";
  meshDomain = "mesh.${baseDomain}";
  vaultMeshDomain = "vault.${meshDomain}";
  desktopTailscaleIp = "100.64.0.1";
in
{
  networking = {
    hosts = {
      "127.0.0.1" = [
        baseDomain
        headscaleDomain
        vaultMeshDomain
      ];
    };
  };

  # Deterministic local CA for the loopback-only vault/headscale vhosts.
  security.pki.certificateFiles = [
    ../../../certs/local-ca.crt
  ];

  services = {
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
        server_url = "https://${headscaleDomain}";
        dns = {
          magic_dns = true;
          base_domain = meshDomain;
          nameservers.global = [
            "1.1.1.2"
            "1.0.0.2"
          ];
          search_domains = [ meshDomain ];
          extra_records = [
            {
              name = vaultMeshDomain;
              type = "A";
              value = desktopTailscaleIp;
            }
          ];
        };
      };
    };

    vaultwarden = {
      enable = true;
      environmentFile = config.sops.secrets."vaultwarden_env".path;
      config = {
        DOMAIN = "https://${vaultMeshDomain}";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        SIGNUPS_ALLOWED = true;
        SIGNUPS_DOMAINS_WHITELIST = "gmail.com";
      };
    };

    caddy = {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/duckdns@v0.5.0" ];
        hash = "sha256-hdJoUoWpDZEz367Rwhagz5040TMHBReLY+hhHjMfwgM=";
      };
      environmentFile = config.sops.templates."caddy_env".path;
      virtualHosts."${baseDomain}" = {
        extraConfig = ''
          tls {
            dns duckdns {env.DUCKDNS_API_TOKEN}
          }
          respond 204
        '';
      };
      virtualHosts."${headscaleDomain}" = {
        extraConfig = ''
          tls ${../../../certs/local-leaf.crt} ${config.sops.secrets."caddy_tls_key".path}
          reverse_proxy 127.0.0.1:8080
        '';
      };
      virtualHosts."${vaultMeshDomain}" = {
        extraConfig = ''
          tls ${../../../certs/local-leaf.crt} ${config.sops.secrets."caddy_tls_key".path}
          reverse_proxy 127.0.0.1:8222
        '';
      };
    };
  };

  # Tailscale reaches Headscale through Caddy; delay startup until ingress is up.
  systemd.services.tailscaled = {
    after = [ "caddy.service" ];
    wants = [ "caddy.service" ];
  };

  # Headscale ingress: Caddy fronts Headscale and Vaultwarden on 80/443; STUN on 3478.
  networking.firewall = {
    allowedTCPPorts = [
      80
      443
    ];
    allowedUDPPorts = [ 3478 ];
  };

  sops.secrets."duckdns_password" = {
    restartUnits = [ "ddclient.service" ];
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

  sops.secrets."vaultwarden_env" = {
    owner = "vaultwarden";
    mode = "0400";
    restartUnits = [ "vaultwarden.service" ];
  };
}
