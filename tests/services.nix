{ pkgs, src }:
pkgs.runCommand "check-services" {
  nativeBuildInputs = with pkgs; [
    findutils
    gnugrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  ! grep -q "tls internal" roles/server/system/caddy.nix
  test "$(grep -c 'dns duckdns' roles/server/system/caddy.nix)" -eq 1
  grep -q "certs/local-ca.crt" roles/server/system/caddy.nix
  grep -q "caddy_tls_key" roles/server/system/caddy.nix
  grep -q "caddy_env" roles/server/system/caddy.nix
  ! grep -q "SSL_CERT_FILE" roles/server/system/caddy.nix
  grep -q "vaultwarden_env" roles/server/system/vaultwarden.nix
  grep -q "useSystemdActivation = true" modules/security/sops.nix
  grep -q "Headscale ingress" roles/server/system/headscale.nix
  grep -q "nix-on-droid.cachix.org" modules/system/cachix.nix
  grep -q "hyprland.cachix.org" modules/system/cachix.nix

  touch $out
''
