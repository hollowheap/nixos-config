# System services & network robustness review
Review-ID: V09
Mode: robustness
Scope: system services/network

## Verdict
- Biggest risk: Vaultwarden and Headscale state (`/var/lib/{vaultwarden,headscale}`) has no backup of any kind, while the same disk holds the only age-decryptable secrets.
- Biggest missing option: `services.vaultwarden.backupDir` exists in the module and is unset; `services.headscale.settings.policy.path` is also unset, so the tailnet is allow-all.
- Seam worth changing: ingress ownership is split across `caddy.nix`, `headscale.nix`, `vaultwarden.nix` with domains imported by value (`domains.nix`), and firewall ports are declared in three files with no interface scoping.

## Findings
### F1: No backup or restore path for vault, coordination DB, or CA state
- Current: `roles/server/system/vaultwarden.nix:13`, `roles/server/system/headscale.nix:13`; no `services.vaultwarden.backupDir`, no restic/borg anywhere.
- Gap: Vaultwarden stores sqlite at `/var/lib/vaultwarden`; Headscale at `/var/lib/headscale/db.sqlite`. Neither is copied, snapshotted, or shipped off-host. `caddy_ca_key` in `secrets.yaml` is the only copy of the CA key.
- Failure/impact: single SSD fault, bad upgrade, or `rm -rf` loses every password and the mesh identity; admin PGP key only recovers secrets, not data.
- Config:
```nix
services.vaultwarden.backupDir = "/var/backup/vaultwarden"; # module ships sqlite-safe timer
services.restic.backups.lacuna = {
  paths = [ "/var/lib/vaultwarden" "/var/lib/headscale" "/var/lib/caddy" ];
  repository = "sftp:acervus:/srv/backup/lacuna";
  passwordFile = config.sops.secrets."restic_password".path;
  initialize = true;
  timerConfig.OnCalendar = "hourly";
};
```
- Source: https://github.com/NixOS/nixpkgs/blob/release-26.05/nixos/modules/services/security/vaultwarden/default.nix ; https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html
- Default check: `backupDir` defaults `null`; no timer generated unless set.
- Confidence: verified

### F2: Vaultwarden signups are effectively open, and rate limits collapse to one bucket
- Current: `roles/server/system/vaultwarden.nix:20-21` (`SIGNUPS_ALLOWED = true`, gmail whitelist); no `SMTP_*`, no `IP_HEADER`.
- Gap: `SIGNUPS_ALLOWED` already defaults to `true`, so the whitelist is inert; `SIGNUPS_VERIFY` needs SMTP and is therefore unusable. `IP_HEADER` defaults to `X-Real-IP`, which Caddy's `reverse_proxy` does not set, so every request is attributed to `127.0.0.1` and shares one login rate-limit bucket.
- Failure/impact: anyone who can reach 443 with `Host: vault.mesh…` registers an account, or exhausts the global login bucket and locks the owner out. No email verification means typo/abuse accounts are indistinguishable.
- Config:
```nix
services.vaultwarden.config = {
  SIGNUPS_ALLOWED = false;            # whitelist then becomes the allowlist
  SIGNUPS_DOMAINS_WHITELIST = "gmail.com";
  IP_HEADER = "X-Forwarded-For";      # Caddy sets XFF, not X-Real-IP
  SENDS_ALLOWED = false;
};
```
- Source: https://github.com/dani-garcia/vaultwarden/blob/main/.env.template
- Default check: `SIGNUPS_ALLOWED=true`, `SIGNUPS_VERIFY=false`, `IP_HEADER=X-Real-IP` upstream.
- Confidence: verified

### F3: Caddy listens on every interface; admin API open to any local user
- Current: `roles/server/system/caddy.nix:13-16` opens 80/443 globally; no `bind`; `services.caddy` relies on module defaults; `enableReload` defaults true, so `admin localhost:2019` stays on.
- Gap: 80 is unnecessary (DNS-01, no HTTP-01). Vault/Headscale vhosts are host-matched, so any LAN or café-Wi-Fi peer can reach them with a spoofed `Host` header. `localhost:2019` is unauthenticated; `steve` (`modules/system/users.nix:7-10`) can POST a config that `file_server`s `/run/secrets-rendered/caddy_env` (Caddy-readable) and exfiltrate the DuckDNS token. No access logs, no ACME contact, infinite `grace_period` (reload can hang).
- Failure/impact: mesh-only assumption is false; local user escalates to caddy-owned secrets; expired-cert or DNS-01 outages are invisible without logs.
- Config:
```nix
networking.firewall = {
  allowedTCPPorts = [ ];
  interfaces.tailscale0.allowedTCPPorts = [ 443 ];
  interfaces.lo.allowedTCPPorts = [ 443 ];
};
services.caddy.enableReload = false;
services.caddy.globalConfig = "admin off\ngrace_period 10s";
services.caddy.email = "admin@example.com";
services.caddy.virtualHosts."${domains.vaultMesh}".logFormat = "level INFO";
```
- Source: https://caddyserver.com/docs/caddyfile/options (admin, grace_period, log, metrics) ; https://github.com/NixOS/nixpkgs/blob/release-26.05/nixos/modules/services/web-servers/caddy/default.nix
- Default check: admin defaults to `localhost:2019`; `enableReload=true` requires the admin API.
- Confidence: verified

### F4: Internal TLS is hand-rolled static PEM with no renewal or expiry watch
- Current: `roles/server/system/caddy.nix:20-22` trusts `certs/local-ca.crt`; `headscale.nix:38` and `vaultwarden.nix:27` both point at the same `certs/local-leaf.crt`; `sops.secrets."caddy_tls_key"` only holds the leaf key.
- Gap: certs are repo files, not derived from `services.caddy.pki`; nothing regenerates them. `caddy_ca_key` in `secrets.yaml` is never referenced (dead material). One leaf must carry SANs for both names or one vhost fails.
- Failure/impact: silent expiry breaks `tailscale up` (Headscale URL) and all vault clients at once; no alert precedes it. Rotating the key invalidates the committed cert.
- Config: drop committed certs and the CA trust file; let Caddy persist and renew a local CA in `dataDir`:
```nix
services.caddy.virtualHosts."${domains.headscale}".extraConfig = ''
  tls internal
  reverse_proxy 127.0.0.1:8080
'';
```
- Source: https://caddyserver.com/docs/caddyfile/options (pki ca, `tls internal` installs trust) ; https://caddyserver.com/docs/caddyfile/directives/tls
- Default check: `tls internal` issues from a CA persisted in `/var/lib/caddy` and renews automatically; current code forbids it (`tests/services.nix:11`).
- Confidence: verified (expiry dates UNVERIFIED — no openssl available here)

### F5: Headscale has no ACL policy, no node expiry, no proxy trust, and DERP disabled
- Current: `roles/server/system/headscale.nix:13-33` sets only `server_url` and DNS; `:50` opens UDP 3478.
- Gap: `policy.path` is unset, so Headscale's default is allow-all. `node.expiry` defaults to `0` (never). `trusted_proxies` is empty, so Caddy-fronted requests log as `127.0.0.1`. `derp.server.enabled` defaults false, so nothing listens on 3478 while the port stays open; clients depend on `controlplane.tailscale.com` for the DERP map.
- Failure/impact: a stolen phone or ephemeral guest key reaches Vaultwarden and sshd on lacuna with no segmentation; rotated/expired devices stay authorized; symmetric-NAT clients rely on Tailscale Inc. infrastructure and leak DERP metadata.
- Config:
```nix
services.headscale.settings = {
  policy.path = ./acl.hujson;                       # default deny, allow admin -> vault:443
  trusted_proxies = [ "127.0.0.1/32" ];
  node.expiry = "180d";
  derp.server = { enabled = true; region_id = 999; stun_listen_addr = "0.0.0.0:3478"; };
};
```
- Source: https://github.com/juanfont/headscale/blob/main/config-example.yaml ; https://headscale.net/stable/ref/policy/
- Default check: `policy.path=""`, `node.expiry=0`, `trusted_proxies=[]`, `derp.server.enabled=false`.
- Confidence: verified

### F6: Vault address is a hardcoded mesh IP decoupled from allocation
- Current: `roles/server/system/domains.nix:6` hardcodes `desktopTailscaleIp = "100.64.0.1"`, consumed by `headscale.nix:25-31` `extra_records`.
- Gap: Headscale allocates sequentially from `100.64.0.0/10`; `100.64.0.1` is simply whichever node registered first. Re-registering lacuna (or deleting the node) shifts it, and the record still points at the old address. Nothing verifies the record matches `headscale nodes list`.
- Failure/impact: `vault.mesh…` resolves to a stale or unrelated device; clients get TLS-name mismatch or a closed port, and the vault appears "down" while the service is healthy.
- Config: serve the vault on the node's MagicDNS name and drop the pin, or derive it:
```nix
dns.extra_records = [ { name = domains.vaultMesh; type = "A"; value = config.server.meshIp; } ];
```
- Source: https://github.com/juanfont/headscale/blob/main/config-example.yaml (prefixes, allocation)
- Default check: sequential allocation, first free address wins; no static-IP option in Headscale config.
- Confidence: verified

### F7: sshd runs upstream permissive defaults on all interfaces
- Current: `modules/services/system-services.nix:6` only sets `openssh.enable = true`.
- Gap: NixOS defaults are `PasswordAuthentication = true`, `KbdInteractiveAuthentication = true`, `PermitRootLogin = "prohibit-password"`, `openFirewall = true`. No `AllowUsers`, no bind restriction.
- Failure/impact: port 22 is open on Wi-Fi/Ethernet with password auth enabled; any later user with a real password is brute-forceable, root may log in by key, and journal fills with scanner noise. Account passwords are empty today (`users.nix:14`), which masks the problem rather than fixing it.
- Config:
```nix
services.openssh = {
  openFirewall = false;
  settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
    AllowUsers = [ "hollowheap" ];
  };
};
networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
```
- Source: https://github.com/NixOS/nixpkgs/blob/release-26.05/nixos/modules/services/networking/ssh/sshd.nix
- Default check: exactly the three permissive defaults above; `openFirewall=true`.
- Confidence: verified

### F8: ddclient cannot read its root-only sops secret (DynamicUser)
- Current: `roles/server/system/ddclient.nix:15-17` declares `duckdns_password` with no `owner`/`mode`; consumer at `:11` is `passwordFile`.
- Gap: sops-nix defaults to `root:root 0400`. The NixOS ddclient unit is `DynamicUser = true` and its `ExecStartPre` runs as that dynamic user to `replace-secret` the password file, so it gets EACCES. `usev4` also duplicates the module default and no IPv6 is configured.
- Failure/impact: ddclient exits non-zero, the public record freezes at the last IP, and after a DHCP lease change Headscale becomes unreachable for every remote client — a silent, delayed outage.
- Config:
```nix
systemd.services.ddclient.serviceConfig.LoadCredential =
  [ "duckdns=${config.sops.secrets."duckdns_password".path}" ];
services.ddclient.passwordFile = "/run/credentials/ddclient.service/duckdns";
# optional: services.ddclient.usev6 = "webv6, webv6=ipify-ipv6";
```
- Source: https://github.com/NixOS/nixpkgs/blob/release-26.05/nixos/modules/services/networking/ddclient.nix ; https://github.com/Mic92/sops-nix
- Default check: sops-nix `mode="0400"`, `owner="root"`; ddclient `DynamicUser=true`.
- Confidence: verified by code reading (runtime failure UNVERIFIED — no deployment access)

### F9: No health, cert, disk, or dead-man alerting
- Current: no monitoring, no `systemd` `OnFailure`, no Prometheus/exporter, no timer beyond `nix.gc` (`modules/system/nix.nix:11-19`).
- Gap: failures that matter here are silent: leaf expiry, ddclient stall, Headscale refusing logins, Vaultwarden disk full.
- Failure/impact: discovery happens when a password is needed, which is the worst moment; RPO is unbounded because outages are only noticed on use.
- Config:
```nix
systemd.services.cert-check = {
  path = [ pkgs.openssl pkgs.curl ];
  script = ''openssl x509 -checkend 1209600 -noout -in ${../../certs/local-leaf.crt} \
    || curl -fsS "https://hc-ping.com/$HC_UUID/fail"'';
};
systemd.timers.cert-check.timerConfig.OnCalendar = "daily";
```
- Source: https://www.freedesktop.org/software/systemd/man/systemd.timer.html ; https://caddyserver.com/docs/caddyfile/options (metrics global option, admin endpoint only)
- Default check: nothing is enabled by default; no scraper exists on either host.
- Confidence: verified

### F10: Secrets bootstrap trusts one host key with no recovery recipient
- Current: `modules/security/sops.nix:8` (`age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]`); `.sops.yaml:4-10` encrypts only to lacuna's age key plus admin PGP.
- Gap: the age identity is a machine-generated host key. Reinstall, `ssh-keygen -A` after host-key deletion, or disk replacement makes every secret undecryptable. `useSystemdActivation = true` (`:7`) means dependents fail immediately when that unit fails; there is no documented restore procedure and no second age recipient for automation.
- Failure/impact: Caddy starts without `DUCKDNS_API_TOKEN`, Vaultwarden without `ADMIN_TOKEN`, ddclient without its token — all fail at once, and recovery depends on the admin PGP key being available offline.
- Config:
```nix
sops.age.keyFile = "/var/lib/sops-nix/age.key"; # generated once, backed up offline
# .sops.yaml: add a second age recipient (offline/recovery) to key_groups
```
- Source: https://github.com/Mic92/sops-nix
- Default check: no fallback identity; host-key path is the sole `age.sshKeyPaths` entry.
- Confidence: verified

### F11: Nix can fill the disk; roaming DoT is strict-only
- Current: `modules/system/nix.nix:2-20` (weekly GC, `--delete-older-than 7d`, no free-space guard); `modules/services/network-services.nix:5-18` (`DNSOverTLS = true`, only Cloudflare resolvers).
- Gap: `min-free`/`max-free` default to 0, so a large build or `nixos-rebuild` can consume `/var` until sqlite writes fail. Strict DoT to two Cloudflare IPs means captive portals and filtered networks black-hole all DNS, including the Headscale name.
- Failure/impact: disk full corrupts nothing but stalls Vaultwarden/Headscale mid-write; strict DoT makes `tailscale up` impossible on hotel/café Wi-Fi until resolved.conf is edited.
- Config:
```nix
nix.settings = { min-free = "5G"; max-free = "20G"; };
services.resolved.settings.Resolve = {
  DNSOverTLS = "opportunistic";      # keep DoT, allow plaintext fallback
  FallbackDNS = [ "9.9.9.9#dns.quad9.net" ];
};
```
- Source: https://nix.dev/manual/nix/latest/command-ref/conf-file ; https://www.freedesktop.org/software/systemd/man/resolved.conf.html
- Default check: `min-free=0`, `max-free=0`; `DNSOverTLS` accepts `yes`/`no`/`opportunistic`.
- Confidence: verified

## Exposure map
- caddy base vhost -> `0.0.0.0:80,443` -> DuckDNS DNS-01 public cert -> none (`respond 204`) -> no backup needed.
- headscale -> `127.0.0.1:8080` behind Caddy -> static `local-leaf.crt` -> preauth keys, no ACL, no expiry -> no DB backup.
- vaultwarden -> `127.0.0.1:8222` behind Caddy -> static `local-leaf.crt` -> master password + optional 2FA, signups open, no SMTP -> no DB backup.
- sshd -> `0.0.0.0:22` (module `openFirewall`) -> none -> pubkey plus password auth -> n/a.
- ddclient -> outbound HTTPS to DuckDNS -> TLS verified (`ssl=true`) -> account token from sops -> cache in `/var/lib/ddclient`.
- headscale DERP -> UDP 3478 open -> no embedded DERP configured -> no listener -> n/a.

## Failure modes
- Cert expiry -> static leaf, no renewal -> silent mesh/vault outage; no alert until F4/F9 fixed.
- DNS-01 failure -> token only in `/run/secrets-rendered/caddy_env`; ACME errors only at ERROR level -> base cert expiry unnoticed, no `email` for CA notices.
- Invalid Caddy config after switch -> `enableReload=true`, `ExecReload` validation fails but admin API remains the only path; `grace_period` infinite can hang reload.
- Headscale ACL lockout -> no policy at all today; once added, `policy.path` is a Nix-store file, so a bad ACL requires a rebuild (no `headscale policy` rollback documented).
- Vaultwarden data loss -> no backup timer, no restic -> total loss; restore procedure untested.
- Weak/absent admin token -> token in `vaultwarden_env`; hashing (argon2) unverified from outside -> assume plaintext until checked.
- SMTP blocked -> no SMTP configured at all -> no verification, no 2FA email, no emergency-access mail.
- ddclient stale IP -> DynamicUser/0400 mismatch -> record frozen; also only A record updated, no AAAA.
- Firewall lockout -> 80/443 and 22 open on all interfaces -> exposure rather than lockout; `nixos-rebuild switch` over SSH stays safe.
- sshd lockout -> password auth still on, no `AllowUsers` -> brute force, not lockout; adding `AllowUsers` without a tested key would lock out.
- Journal disk fill -> default 10%/4 GiB cap -> bounded; not a real risk.
- Clock drift -> timesyncd default -> ACME and TOTP tolerate it; no NTS needed.
- Nix store corruption -> no `nix-store --verify` timer, no `min-free` -> rebuild may fail mid-write on a full disk.
- Unattended upgrade breakage -> `system.autoUpgrade` absent -> no surprise breakage, but also no patching; deliberate but undocumented.
- Secret decryption failure at boot -> host-key identity, single recipient -> all four services fail together; no documented recovery.
- Mesh/TLS trust break -> `security.pki.certificateFiles` trusts a CA whose key sits unused in sops -> compromise of `caddy_ca_key` is undetectable and unrevocable.

## Seams
- Ingress duplication: three modules each write `services.caddy.virtualHosts` and repeat `tls certs/local-leaf.crt …` (`caddy.nix:31`, `headscale.nix:36`, `vaultwarden.nix:25`); no shared `server.ingress` option or TLS helper.
- Domain ownership: `domains.nix` is `import`ed by value in four files (`caddy.nix:4`, `headscale.nix:4`, `vaultwarden.nix:4`, `ddclient.nix:4`) — not a module option, so hosts/tests cannot override, and `desktopTailscaleIp` lives in a domain table.
- Firewall ownership: 80/443 in `caddy.nix:13`, 3478 in `headscale.nix:50`, 22 implicitly via `openssh.openFirewall` in `system-services.nix:6` — no single exposure declaration, no interface scoping.
- `networking.hosts."127.0.0.1"` is written independently three times (`caddy.nix:7-12`, `headscale.nix:7-11`, `vaultwarden.nix:7-11`); merge works, ownership does not.
- Test/spec contradiction: `tests/services.nix:11` asserts `! grep "tls internal"` while `artifacts/specs.md:52` verifies `grep -q "tls internal"`; S09 is marked `[x]` with a failing verify command.
- Tests assert implementation strings, including a comment (`tests/services.nix:19` greps `"Headscale ingress"`), so refactors break CI without behavior change.
- Secret ownership is per-service and inconsistent: `caddy_tls_key` and `caddy_env` set `owner`/`mode`, `duckdns_password` does not (`ddclient.nix:15-17`) — no central secret manifest to audit.
- Role composition is correct: only `hosts/lacuna/default.nix:12` imports `roles/server/system`; acervus stays clean, matching S08.

## Rejected defaults
- journald `SystemMaxUse` — default is 10% of `/var` capped at 4 GiB; adding limits is noise.
- ddclient `interval`, `ssl`, `wildcard=YES`, persistent cache — module already sets sane values; only the secret permission is broken.
- ddclient `usev4` — current value is literally the module default; the line adds nothing.
- Vaultwarden `ROCKET_ADDRESS` default `::1` — correctly overridden to `127.0.0.1`; no change.
- Headscale Postgres — upstream and module both discourage it; sqlite with WAL is the intended path.
- Headscale `metrics_listen_addr` — defaults to `127.0.0.1:9090` and there is no scraper; enabling metrics now is dead config.
- Caddy `servers.timeouts` — `read_header 1m`, `idle 5m`, `read_body_idle 1m` already mitigate slowloris; only `grace_period` matters because reload is on.
- NUT/UPS — both hosts are laptops with batteries; NUT adds a dependency without a new failure domain covered.
- fail2ban/sshguard — with `PasswordAuthentication=false` the sshd jail only trims log noise; fix F7 first.
- Prometheus + node-exporter on a single laptop with no scraper — an exporter nobody scrapes is not monitoring; F9's dead-man switch is the cheaper equivalent.
- `nix.optimise.automatic` plus `auto-optimise-store` — redundant work, harmless; leave as is.

## Open questions
- Does lacuna actually receive inbound 80/443 from the internet, or is it behind CGNAT (making the public vhost and 3478 moot)?
- Do `certs/local-leaf.crt` SANs cover both `headscale.<base>` and `vault.mesh.<base>`, and what is the expiry date?
- Is `ADMIN_TOKEN` stored as an argon2 PHC string or plaintext?
- Should `steve` keep a local shell on a host that runs the vault and a rootful podman socket?
- Is `100.64.0.1` in fact lacuna's node, or an assumption from first registration order?
- Will acervus become the backup/monitoring target, or should backups go to external storage?
- Does the ISP provide usable IPv6 (would justify `usev6` and AAAA records)?
