# V09: System Services & Network — Robustness Review

**User-visible outcome**: Server services (Caddy internal TLS + proxy, Headscale, Vaultwarden, ddclient), `tailscaled` CA trust, firewall, SSH, Wi-Fi/`iwd`, and `sops-nix` secrets isolate exposure to loopback/mesh without leaked admin endpoints or stale DNS.

**End-to-end verification command & observed result**:
```bash
nix build .#checks.x86_64-linux.services .#checks.x86_64-linux.users --no-link
nix eval --json .#nixosConfigurations.lacuna.config.services --apply 's: { caddy = s.caddy.enable; headscale = s.headscale.enable; vaultwarden = s.vaultwarden.enable; ddclient = s.ddclient.enable; openssh = s.openssh.enable; }'
```
Observed: `check-services` and `check-users` **PASSED**; `caddy`, `headscale`, `vaultwarden`, `ddclient`, `openssh` all `true` on `lacuna`; `acervus` runs `openssh = true`.

---

## Lens ledger

| Lens | Status | Reason |
|---|---|---|
| simplicity | loaded | Always on. `tailscaled` `SSL_CERT_FILE` pointed into Caddy's internal PKI state (`roles/server/system/default.nix:12-13`) instead of issuing public DNS-01 certs across subdomains (`caddy.nix:30-34` already wires `caddy-dns/duckdns` on `domains.base`); `acl.hujson` hardcodes sequential IPs instead of tag-based policy. |
| architecture | loaded | **High**: Caddy TCP `443` blocked on physical WAN/LAN interfaces (`caddy.nix:14-16`), preventing new Tailscale nodes from joining Headscale, while `hosts/lacuna/default.nix:21-25` opens raw ports `1883`, `8083`, `8090` on `wlan0`. |
| api | loaded | Non-declarative auth (`modules/system/users.nix`): `mutableUsers = true`, `hashedPasswordFile = null`, `authorizedKeys.keys = []` combined with `PasswordAuthentication = false` lock out SSH (`R13`). |
| data | loaded | `ddclient.usev6 = ""` drops IPv6 DuckDNS records; `acl.hujson:2-6` hardcodes `100.64.0.1` / `fd7a:115c:a1e0::1`. |
| security | loaded | **High**: Unauthenticated ports `[1883 8083 8090]` exposed on `wlan0`; `tailscaled` `SSL_CERT_FILE` blinds public CA trust (breaking public DERP / cold-start cert lookup); `.sops.yaml` omits `acervus` while `acervus` imports `hardware/wifi.nix`; `acl.hujson` drops mesh port `22`. |
| performance | loaded | `networking.wireless.iwd.settings` empty (`{ }`), defaulting to world domain `00` (limiting channels and Tx power). |
| tests | loaded | `tests/services.nix:21` checks `caddy.nix` for `SSL_CERT_FILE`, bypassed by `roles/server/system/default.nix:12`; `R12` checks `default.nix` for `dns duckdns` (actual plugin sits in `caddy.nix:33`); tests use static `rg` patterns over Nix eval. |
| ui | loaded | Headless daemon slice; Vaultwarden enforces `SIGNUPS_ALLOWED = false`. Web vault runtime UI rendering is **UNVERIFIED**. |

---

## Failure modes

### 1. [High] TCP `443` blocked on physical interfaces while STUN UDP `3478` is exposed globally
- **Current**: [roles/server/system/caddy.nix:13-17](file:///home/hollowheap/repos/nixos-config/roles/server/system/caddy.nix#L13-L17), [roles/server/system/headscale.nix:69-70](file:///home/hollowheap/repos/nixos-config/roles/server/system/headscale.nix#L69-L70)
- **Gap**: `allowedTCPPorts = [ ]` and `443` is allowed only on `tailscale0` and `lo`. New nodes trying to authenticate against Headscale (`https://headscale.hollowheap.duckdns.org:443`) cannot reach TCP `443` before joining the mesh.
- **Failure/impact + repro**: Unenrolled nodes time out on initial Tailscale login (`nix eval --json .#nixosConfigurations.lacuna.config.networking.firewall.allowedTCPPorts` -> `[ ]`).
- **Config minimal shape**: Expose `443` through Caddy while scoping Vaultwarden vhost strictly to tailnet/loopback clients (`remote_ip private_ranges 100.64.0.0/10 fd7a:115c:a1e0::/48`) or document the bootstrap tunnel path.
- **Source**: `R34`, `R36`, [ARCHITECTURE.md](file:///home/hollowheap/repos/nixos-config/.artifacts/ARCHITECTURE.md).
- **Default check**: NixOS `allowedTCPPorts` defaults to `[ ]`.
- **Confidence**: Verified.

### 2. [High] Raw TCP ports `1883`, `8083`, `8090` opened on untrusted Wi-Fi `wlan0`
- **Current**: [hosts/lacuna/default.nix:21-25](file:///home/hollowheap/repos/nixos-config/hosts/lacuna/default.nix#L21-L25)
- **Gap**: `wlan0.allowedTCPPorts = [ 1883 8083 8090 ]` exposes unauthenticated MQTT/proxy ports directly on public Wi-Fi LANs with no owning service or Caddy boundary.
- **Failure/impact + repro**: Local processes on `0.0.0.0:{1883,8083,8090}` are reachable on public Wi-Fi networks, violating `AGENTS.md` loopback/Caddy boundary (`nix eval --json .#nixosConfigurations.lacuna.config.networking.firewall.interfaces.wlan0.allowedTCPPorts`).
- **Config minimal shape**: Remove `wlan0.allowedTCPPorts` from `hosts/lacuna/default.nix` and terminate traffic through Caddy on loopback/mesh.
- **Source**: `R34`, `AGENTS.md`.
- **Default check**: Interface ports default to `[ ]`.
- **Confidence**: Verified.

### 3. [High] Mutable users + blank password + empty `authorizedKeys` with `PasswordAuthentication = false` (`R13`)
- **Current**: [modules/system/users.nix:12-25](file:///home/hollowheap/repos/nixos-config/modules/system/users.nix#L12-L25), [modules/services/system-services.nix:8-13](file:///home/hollowheap/repos/nixos-config/modules/services/system-services.nix#L8-L13)
- **Gap**: `mutableUsers = true`, `hashedPasswordFile = null`, and `openssh.authorizedKeys.keys = [ ]`, while OpenSSH disables password/kbd-interactive auth.
- **Failure/impact + repro**: SSH access requires manual out-of-band key setup (`nix eval --json .#nixosConfigurations.lacuna.config.users.mutableUsers` -> `true`; `hashedPasswordFile` -> `null`).
- **Config minimal shape**: Set `users.mutableUsers = false`, `sops`-backed `hashedPasswordFile`, and declarative `openssh.authorizedKeys.keys`.
- **Source**: `R13`.
- **Default check**: NixOS defaults `mutableUsers = true`.
- **Confidence**: Verified.

### 4. [High] `tailscaled` `SSL_CERT_FILE` overrides system CA bundle and breaks cold boot
- **Current**: [roles/server/system/default.nix:11-13](file:///home/hollowheap/repos/nixos-config/roles/server/system/default.nix#L11-L13)
- **Gap**: Setting `SSL_CERT_FILE = "/var/lib/caddy/.local/share/caddy/pki/authorities/local/root.crt"` replaces Go's system CA bundle (breaking public HTTPS such as upstream DERP fetches) and fails if Caddy has not yet generated `root.crt`.
- **Failure/impact + repro**: `nix eval --raw .#nixosConfigurations.lacuna.config.systemd.services.tailscaled.environment.SSL_CERT_FILE`.
- **Config minimal shape**: Use DuckDNS DNS-01 public certs in Caddy (`R12`) or merge the Caddy root CA into `security.pki.certificateFiles` instead of overwriting `SSL_CERT_FILE`.
- **Source**: `R12`, `R38`.
- **Default check**: `tailscaled` uses system CA bundle unless `SSL_CERT_FILE` is set.
- **Confidence**: Verified.

### 5. [High] Headscale ACL omits TCP `22` (SSH) and hardcodes sequential mesh IPs
- **Current**: [roles/server/system/acl.hujson:1-20](file:///home/hollowheap/repos/nixos-config/roles/server/system/acl.hujson#L1-L20)
- **Gap**: `acl.hujson` only accepts traffic to `443` and hardcodes `100.64.0.1` / `fd7a:115c:a1e0::1`, blocking tailnet SSH on `22` even though `system-services.nix` opens `22` on `tailscale0`.
- **Failure/impact + repro**: Tailnet SSH to `lacuna` drops at the Headscale policy boundary (`grep -q '"22"' roles/server/system/acl.hujson` fails).
- **Config minimal shape**: Add tag/admin ACL rules allowing port `22` alongside `443`.
- **Source**: `R36`.
- **Default check**: Unset policy defaults allow-all; custom ACL denies unlisted ports.
- **Confidence**: Verified.

### 6. [Medium] `acervus` imports `hardware/wifi.nix` (`wireless_env`) without an age key in `.sops.yaml`
- **Current**: [hosts/acervus/default.nix:14](file:///home/hollowheap/repos/nixos-config/hosts/acervus/default.nix#L14), [hardware/wifi.nix:11](file:///home/hollowheap/repos/nixos-config/hardware/wifi.nix#L11), [.sops.yaml:1-10](file:///home/hollowheap/repos/nixos-config/.sops.yaml#L1-L10)
- **Gap**: `hardware/wifi.nix` consumes `config.sops.secrets."wireless_env".path`, but `.sops.yaml` only lists `lacuna` (`rg "acervus" .sops.yaml` returns nothing).
- **Failure/impact + repro**: `acervus` cannot decrypt `secrets.yaml` on activation.
- **Config minimal shape**: Add `acervus` host age recipient to `.sops.yaml` and rekey `secrets.yaml`.
- **Source**: `R06`, `AGENTS.md`.
- **Default check**: `sops-nix` fails on undecryptable host key.
- **Confidence**: Verified.

### 7. [Medium] `iwd` lacks regulatory `Country` and `wifi.nix` pins SAE-only without WPA2 fallback (`R46`)
- **Current**: [hardware/wifi.nix](file:///home/hollowheap/repos/nixos-config/hardware/wifi.nix)
- **Gap**: `networking.wireless.iwd.settings` evaluates to `{ }`; profiles specify `key-mgmt = "sae"` only.
- **Config minimal shape**: Set `iwd.settings.General.Country` and WPA2/WPA3 transition `key-mgmt`.
- **Confidence**: Verified.

### 8. [Medium] No certificate expiry monitoring (`R38`) and disabled `ddclient` IPv6 + alerting (`R37`)
- **Current**: [roles/server/system/caddy.nix:28](file:///home/hollowheap/repos/nixos-config/roles/server/system/caddy.nix#L28), [roles/server/system/ddclient.nix:11-17](file:///home/hollowheap/repos/nixos-config/roles/server/system/ddclient.nix#L11-L17)
- **Gap**: No timer checks internal/ACME cert expiry; `ddclient.usev6 = ""` drops IPv6 DNS updates and `ddclient` has no `OnFailure` unit.
- **Config minimal shape**: Enable `ddclient.usev6`, add `OnFailure` alerting, and monitor cert expiration.
- **Confidence**: Verified.

### 9. [Low] `tests/services.nix:21` `SSL_CERT_FILE` guard bypassed by `default.nix` & Vaultwarden `SIGNUPS_DOMAINS_WHITELIST`
- **Current**: [tests/services.nix:21](file:///home/hollowheap/repos/nixos-config/tests/services.nix#L21), [roles/server/system/vaultwarden.nix:22](file:///home/hollowheap/repos/nixos-config/roles/server/system/vaultwarden.nix#L22)
- **Gap**: `tests/services.nix` checks `caddy.nix` only while `roles/server/system/default.nix:12` sets `SSL_CERT_FILE`; `SIGNUPS_DOMAINS_WHITELIST = "gmail.com"` is dormant risk if `SIGNUPS_ALLOWED` is toggled.
- **Confidence**: Verified.

---

## Seams

1. **Fragmented Firewall Ownership**: Port allowances split across `modules/services/system-services.nix` (`22` on `tailscale0`), `caddy.nix` (`443` on `tailscale0`/`lo`), `headscale.nix` (`3478` global), and `hosts/lacuna/default.nix` (`wlan0`).
2. **User Auth Seam (`users.nix` vs `system-services.nix`)**: No declarative bridge from `sops` / `authorizedKeys` to `users.users`.
3. **Secrets Decryption Seam (`acervus` vs `.sops.yaml`)**: `acervus` imports `hardware/wifi.nix` without a `.sops.yaml` recipient.
4. **Caddy DNS-01 vs `tailscaled` `SSL_CERT_FILE`**: `caddy.nix:32-34` configures DuckDNS DNS-01 for `domains.base` while subdomains use `tls internal` + `SSL_CERT_FILE` in `default.nix:12`.

---

## Rejected defaults

- `services.openssh.openFirewall = false` + `PasswordAuthentication = false`: Rejected default public SSH exposure.
- `services.caddy.enableReload = false`: Required when `admin off` disables `:2019`.
- `services.vaultwarden.config.{SIGNUPS_ALLOWED,SENDS_ALLOWED} = false`: Properly hardened.
- `networking.firewall.checkReversePath = "loose"`: Required for Tailscale asymmetric routing.
- `users.mutableUsers = true`: Currently left at unsafe default (`R13`).

---

## Blocking Design Forks

1. **Headscale Ingress Boundary & DNS-01 Certificates (`R12`, `R34`, `R36`)** → route to `/design`: expose Caddy TCP `443` externally with DuckDNS DNS-01 certs for `headscale` (restricting `vault` to mesh/loopback) vs keeping WAN `443` closed with manual pre-enrollment.
2. **Declarative User Secrets & Multi-Host Sops Enrollment (`R06`, `R13`)** → route to `/design`: enroll `acervus` in `.sops.yaml` vs split host secret files, and wire declarative `hashedPasswordFile` + `openssh.authorizedKeys.keys` with `mutableUsers = false`.
