{ pkgs, src }:
pkgs.runCommand "check-hardware" {
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

  test -f hardware/hdr.nix
  test -f hardware/hybrid-gpu.nix
  test -f hardware/nvidia.nix
  test -f hardware/touch.nix
  test -f hardware/serial.nix

  rg -q "traits = \[" hosts/lacuna/hardware.nix
  rg -q '"serial"' hosts/lacuna/hardware.nix
  rg -q 'dialout' hardware/serial.nix
  rg -q 'enableRedistributableFirmware' hardware/cpu.nix
  no_match -q 'enableRedistributableFirmware' hardware/bluetooth.nix
  rg -q "hybrid-gpu" hosts/acervus/default.nix
  no_match -q "hybrid-gpu" hosts/lacuna/hardware.nix
  rg -q "desktop.touch = true" hardware/touch.nix
  rg -q "desktop.hdr = true" hardware/hdr.nix
  rg -q "desktop.touch = true" home/hollowheap.nix

  touch $out
''
