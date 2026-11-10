{
  pkgs,
  src,
}:
pkgs.runCommand "check-nix-on-droid" {
  nativeBuildInputs = [ pkgs.ripgrep ];
} ''
  set -euo pipefail
  cd ${src}

  no_match() {
    local rc=0
    rg "$@" || rc=$?
    [ "$rc" -eq 1 ]
  }

  rg -q 'experimental-features = nix-command flakes' nix-on-droid.nix
  rg -q 'termux-setup-storage' nix-on-droid.nix
  rg -q 'termux-wake-lock' nix-on-droid.nix
  rg -q 'termux-reload-settings' nix-on-droid.nix
  no_match -q '^\s+(age|sops)$' nix-on-droid.nix

  touch $out
''
