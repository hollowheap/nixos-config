{ pkgs, src }:
pkgs.runCommand "check-policy" {
  nativeBuildInputs = with pkgs; [
    findutils
    ripgrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  ! rg "hardware/" profiles
  ! rg "config.profile" modules home roles hardware boot
  ! rg "import-tree.*hosts" flake hosts
  ! rg "profiles/desktop" hosts/lacuna/default.nix

  rg -q "roles/server/system" hosts/lacuna/default.nix
  rg -q "homeUserNames" flake/default.nix
  rg -q "inputs.import-tree ./modules" home/hollowheap.nix
  ! rg -q "roles/server" hosts/acervus/default.nix
  ! rg -q "roles/desktop" hosts/acervus/default.nix

  touch $out
''
