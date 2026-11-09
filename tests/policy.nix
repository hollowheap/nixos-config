{ pkgs, src }:
pkgs.runCommand "check-policy" {
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

  no_match "hardware/" profiles
  no_match "config.profile" modules home roles hardware boot
  no_match "import-tree.*hosts" flake hosts
  no_match "profiles/desktop" hosts/lacuna/default.nix

  rg -q "roles/server/system" hosts/lacuna/default.nix
  rg -q "homeUserNames" flake/default.nix
  rg -q "inputs.import-tree ./modules" home/hollowheap.nix
  no_match -q "roles/server" hosts/acervus/default.nix
  no_match -q "roles/desktop" hosts/acervus/default.nix

  touch $out
''
