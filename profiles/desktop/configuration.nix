{ config, ... }:

let
  baseDomain = "hollowheap.duckdns.org";
  headscaleDomain = "headscale.${baseDomain}";
  meshDomain = "mesh.${baseDomain}";
  vaultMeshDomain = "vault.${meshDomain}";
  desktopTailscaleIp = "100.64.0.1";
in
{
  hardware.i2c.enable = true;

  networking.hosts = {
    "127.0.0.1" = [
      baseDomain
      headscaleDomain
      vaultMeshDomain
    ];
  };

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
      virtualHosts."${headscaleDomain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8080
        '';
      };
      virtualHosts."${vaultMeshDomain}" = {
        extraConfig = ''
          reverse_proxy 127.0.0.1:8222
        '';
      };
    };
  };

  sops.secrets."duckdns_password" = {
    restartUnits = [ "ddclient.service" ];
  };

  sops.secrets."vaultwarden_env" = {
    owner = "vaultwarden";
    mode = "0400";
    restartUnits = [ "vaultwarden.service" ];
  };
}
