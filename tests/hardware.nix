{ pkgs, src }:
pkgs.runCommand "check-hardware" {
  nativeBuildInputs = with pkgs; [
    findutils
    gnugrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  test -f hardware/hdr.nix
  test -f hardware/hybrid-gpu.nix
  test -f hardware/nvidia.nix
  test -f hardware/touch.nix

  grep -q "traits = \[" hosts/lacuna/hardware.nix
  grep -q "hybrid-gpu" hosts/acervus/default.nix
  ! grep -q "hybrid-gpu" hosts/lacuna/hardware.nix
  grep -q "home-manager.sharedModules" hardware/touch.nix
  grep -q "home-manager.sharedModules" hardware/hdr.nix

  touch $out
''
