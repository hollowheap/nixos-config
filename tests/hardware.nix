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
  grep -q "desktop.touch = true" hardware/touch.nix
  grep -q "desktop.hdr = true" hardware/hdr.nix
  grep -q "desktop.touch = true" home/hollowheap.nix

  touch $out
''
