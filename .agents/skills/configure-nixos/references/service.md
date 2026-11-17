# Selfhosted Services

## Network & Reverse Proxy

1. Bind backend service listeners exclusively to loopback (`127.0.0.1:<port>`) or mesh (`100.64.0.1:<port>`); never bind daemons directly to `0.0.0.0` for public traffic.
2. Expose HTTP/HTTPS endpoints exclusively through Caddy (`services.caddy.virtualHosts`) with `reverse_proxy`.
3. Add internal service hostnames to `networking.hosts."127.0.0.1"` so local hairpin requests resolve to loopback.

## TLS & Firewall

- Use Caddy `tls internal` or DNS-01 ACME for private or mesh-only virtual hosts.
- Use HTTP-01 ACME only when public DNS records match the host WAN IP.
- Keep host firewall TCP ports limited to `80` and `443` for HTTP services; verify service status, Caddy config reload, and `https://<host>` response after switching.
