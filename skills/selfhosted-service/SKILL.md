---
name: selfhosted-service
description: Host daemon isolation and Caddy reverse proxy protocol. Load ONLY when deploying or modifying host system daemons, Caddy virtualHosts, or TLS. Do NOT load for local user tools.
---

## Workflow

1. Bind daemon strictly to loopback: 127.0.0.1:<port> (or mesh IP 100.64.0.1).
2. Add hairpin resolution to networking.hosts."127.0.0.1".
3. Configure Caddy virtualHost with appropriate TLS strategy (standard HTTP-01, tls internal, or DNS-01).
4. Proxy reverse_proxy 127.0.0.1:<port> through Caddy virtualHosts.
5. Keep networking.firewall.allowedTCPPorts restricted to Caddy ports 80 and 443.

## Rules

- Never configure Caddy with public ACME for domains resolving to private/mesh IPs.
- Never expose raw backend daemon ports directly through the firewall.
- Verify public WAN IP matches DNS resolution before troubleshooting ACME timeouts.
- Verify: Backend daemon responds on loopback and Caddy reverse proxy terminates TLS.

