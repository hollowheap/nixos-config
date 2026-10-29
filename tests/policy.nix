{ pkgs, src }:
pkgs.runCommand "check-policy" {
  nativeBuildInputs = with pkgs; [
    findutils
    gnugrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  ! grep -R "hardware/" profiles
  ! grep -R "config.profile" modules home roles hardware boot
  ! grep -R "import-tree.*hosts" flake hosts
  ! grep -R "profiles/desktop" hosts/lacuna/default.nix

  grep -q "roles/server/system" hosts/lacuna/default.nix
  grep -q "homeUserNames" flake/default.nix
  grep -q "inputs.import-tree ./modules" home/hollowheap.nix
  ! grep -q "roles/server" hosts/acervus/default.nix
  ! grep -q "roles/desktop" hosts/acervus/default.nix

  touch $out
''
