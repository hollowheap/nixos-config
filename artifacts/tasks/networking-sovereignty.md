# Task: Networking, Firewall & Sovereign Services (from overview.md)

- [x] **Firewall:** Open TCP ports 80/443 and UDP port 3478 (STUN/DERP).
- [x] **DNS-over-TLS:** `systemd-resolved` configured with Cloudflare security DNS (`security.cloudflare-dns.com` over TLS).
- [x] **NetworkManager:** `iwd` backend with declarative WiFi and 802.1x enterprise profiles populated from SOPS secret `wireless_env`.
- [x] **Tailscale Client:** `services.tailscale.enable = true` host daemon with `extraSetFlags = [ "--operator=hollowheap" ]` and `useRoutingFeatures = "both"`.
- [x] **Dynamic DNS & Loopback:** `services.duckdns` dynamic IP updater and `networking.hosts` 127.0.0.1 domain overrides for NAT hairpin bypass.
- [x] **Headscale Mesh:** Self-hosted WireGuard control plane with MagicDNS, base domain, search domains, and extra A records.
- [x] **Vaultwarden:** Bitwarden-compatible vault running on `127.0.0.1:8222` bound to MagicDNS domain. Configured declarative signups (`SIGNUPS_ALLOWED = true`, `SIGNUPS_DOMAINS_WHITELIST = "gmail.com"`) and `environmentFile` for `ADMIN_TOKEN`.
- [x] **Dynamic DNS (ddclient):** Synchronize public IP with DuckDNS via `services.ddclient`.
- [x] **Caddy Reverse Proxy:** Reverse proxy terminating TLS for Headscale and Vaultwarden using standard automatic Let's Encrypt certificates.
- [x] **Tailscale Host Registration:** Local host connects directly to local coordinator via `tailscale up --login-server http://127.0.0.1:8080`, preserving state in `/var/lib/tailscale`.
