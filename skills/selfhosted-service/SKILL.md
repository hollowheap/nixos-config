---
name: selfhosted-service
description: Protocol for deploying host system daemons, Caddy reverse proxy virtual hosts, and TLS validation.
---

Deploy sovereign services safely by isolating backend daemons to loopback, routing traffic through Caddy reverse proxy, and choosing the correct TLS validation model.

## Use / Do NOT use

Use when: adding a self-hosted daemon (Vaultwarden, Headscale, etc.), editing Caddy virtualHosts, or setting up domain routing.
Do NOT use when: configuring user CLI tools or local desktop applications.

## Workflow

1. **Binding**: Daemon listens on `127.0.0.1:<port>` (never `0.0.0.0` unless required by UDP STUN/DERP).
2. **Loopback**: Add domain name to `networking.hosts."127.0.0.1"` for local hairpin routing.
3. **TLS Strategy**:
   - *Public Internet (Ports 80/443 forwarded)*: Plain Caddy virtualHost (standard HTTP-01). Check public DNS points to WAN IP first.
   - *Private Mesh / Internal*: Specify `tls internal` to prevent ACME failure loops.
   - *Behind NAT / No Port Forwarding*: Specify `tls { dns <provider> ... }` (DNS-01).
4. **Proxy**: Forward Caddy virtualHost to backend: `reverse_proxy 127.0.0.1:<port>`.
5. **Firewall**: Ensure `networking.firewall.allowedTCPPorts` only exposes Caddy (`80`, `443`), not raw internal daemon ports.

## Rules

1. Never configure Caddy with public ACME for a sub-mesh domain that resolves to a private IP (e.g., `100.64.0.1`).
2. Verify public WAN IP matches DNS record resolution before troubleshooting ACME timeouts.
3. Use declarative dynamic DNS (`services.ddclient`) to keep public domains synced with ISP WAN changes.

## Verification

Backend daemon responds on loopback (`curl -I http://127.0.0.1:<port>`); Caddy terminates TLS and proxies successfully (`curl -I https://<domain>`).
