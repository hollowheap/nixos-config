{ pkgs, src }:
pkgs.runCommand "check-users" {
  nativeBuildInputs = with pkgs; [
    findutils
    ripgrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  rg -q "adminExtraGroups" modules/virtualisation/podman.nix
  rg -q "adminExtraGroups" modules/options/users.nix
  ! rg -q '"podman"' modules/system/users.nix

  touch $out
''
