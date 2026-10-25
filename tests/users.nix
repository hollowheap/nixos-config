{ pkgs, src }:
pkgs.runCommand "check-users" {
  nativeBuildInputs = with pkgs; [
    findutils
    gnugrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  grep -q "adminExtraGroups" modules/virtualisation/podman.nix
  grep -q "adminExtraGroups" modules/options/users.nix
  ! grep -q '"podman"' modules/system/users.nix

  touch $out
''
