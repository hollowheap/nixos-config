{ pkgs, src }:
pkgs.runCommand "check-hardware" {
  nativeBuildInputs = with pkgs; [
    findutils
    ripgrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  test -f hardware/hdr.nix
  test -f hardware/hybrid-gpu.nix
  test -f hardware/nvidia.nix
  test -f hardware/touch.nix

  rg -q "traits = \[" hosts/lacuna/hardware.nix
  rg -q "hybrid-gpu" hosts/acervus/default.nix
  ! rg -q "hybrid-gpu" hosts/lacuna/hardware.nix
  rg -q "desktop.touch = true" hardware/touch.nix
  rg -q "desktop.hdr = true" hardware/hdr.nix
  rg -q "desktop.touch = true" home/hollowheap.nix

  touch $out
''
