# Selfhosted-Service Examples

## Bad
- Binding a daemon to `0.0.0.0:8000` and opening port 8000 in `networking.firewall.allowedTCPPorts`.
- Using default ACME TLS for an internal Tailscale/Headscale mesh IP domain.

## Good
- Bind Vaultwarden to `127.0.0.1:8000`, route via `services.caddy.virtualHosts."vault.example.com"`, and use `tls internal` or DNS-01 challenge.
