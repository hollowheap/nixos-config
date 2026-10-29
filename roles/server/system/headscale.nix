{ config, ... }:

let
  domains = import ./domains.nix;
in
{
  networking.hosts = {
    "127.0.0.1" = [
      domains.headscale
    ];
  };

  services.headscale = {
    enable = true;
    settings = {
      server_url = "https://${domains.headscale}";
      dns = {
        magic_dns = true;
        base_domain = domains.mesh;
        nameservers.global = [
          "1.1.1.2"
          "1.0.0.2"
        ];
        search_domains = [ domains.mesh ];
        extra_records = [
          {
            name = domains.vaultMesh;
            type = "A";
            value = domains.desktopTailscaleIp;
          }
        ];
      };
    };
  };

  services.caddy.virtualHosts."${domains.headscale}" = {
    extraConfig = ''
      tls ${../../../certs/local-leaf.crt} ${config.sops.secrets."caddy_tls_key".path}
      reverse_proxy 127.0.0.1:8080
    '';
  };

  # Tailscale reaches Headscale through Caddy; delay startup until ingress is up.
  systemd.services.tailscaled = {
    after = [ "caddy.service" ];
    wants = [ "caddy.service" ];
  };

  # Headscale ingress: Caddy fronts Headscale and Vaultwarden on 80/443; STUN on 3478.
  networking.firewall.allowedUDPPorts = [ 3478 ];
}
