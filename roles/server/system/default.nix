{ ... }:
{
  imports = [
    ./caddy.nix
    ./headscale.nix
    ./vaultwarden.nix
    ./ddclient.nix
  ];

  # Caddy uses tls internal for loopback vhosts.
  systemd.services.tailscaled.environment.SSL_CERT_FILE =
    "/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt";
}
