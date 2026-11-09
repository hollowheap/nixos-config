{ pkgs, src }:
pkgs.runCommand "check-services" {
  nativeBuildInputs = with pkgs; [
    findutils
    ripgrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  no_match() {
    local rc=0
    rg "$@" || rc=$?
    [ "$rc" -eq 1 ]
  }

  no_match -q "tls internal" roles/server/system/caddy.nix
  test "$(rg -c 'dns duckdns' roles/server/system/caddy.nix)" -eq 1
  no_match -q "certs/local-ca.crt" roles/server/system/caddy.nix
  rg -q "caddy_env" roles/server/system/caddy.nix
  no_match -q "SSL_CERT_FILE" roles/server/system/caddy.nix
  rg -q "vaultwarden_env" roles/server/system/vaultwarden.nix
  rg -q "tls internal" roles/server/system/vaultwarden.nix
  rg -q "tls internal" roles/server/system/headscale.nix
  rg -q "backupDir" roles/server/system/vaultwarden.nix
  rg -q "useSystemdActivation = true" modules/security/sops.nix
  rg -q "Headscale ingress" roles/server/system/headscale.nix
  rg -q "nix-on-droid.cachix.org" modules/system/cachix.nix
  rg -q "hyprland.cachix.org" modules/system/cachix.nix

  touch $out
''
