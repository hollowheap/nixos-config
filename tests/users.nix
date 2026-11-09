{ pkgs, src }:
pkgs.runCommand "check-users" {
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

  rg -q "adminExtraGroups" modules/virtualisation/podman.nix
  rg -q "adminExtraGroups" modules/options/users.nix
  no_match -q '"podman"' modules/system/users.nix

  touch $out
''
