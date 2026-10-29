{ pkgs, src }:
pkgs.runCommand "check-layout" {
  nativeBuildInputs = with pkgs; [
    findutils
    gnugrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  test -f profiles/desktop/default.nix
  test -f profiles/laptop/default.nix
  test -f profiles/vm/default.nix
  test ! -e profiles/desktop/configuration.nix
  test ! -e profiles/laptop/configuration.nix

  test -f roles/desktop/system/default.nix
  test -f home/modules/programs/gui/pear-desktop.nix
  test -f roles/server/system/default.nix
  test -f boot/grub.nix
  test -f boot/tpm.nix
  test -f boot/secure-boot.nix
  test -f boot/minegrub.nix
  test -f boot/kernel.nix
  test -f boot/plymouth.nix
  test ! -e boot/systemd-boot.nix
  test ! -e modules/boot/boot.nix

  test -f hosts/lacuna/hardware.nix
  test -f hosts/acervus/default.nix
  test -f hosts/acervus/hardware-configuration.nix
  test -f nix-on-droid.nix

  test -f home/hollowheap.nix
  test -f home/lib/toolchains.nix
  test -f modules/options/desktop.nix
  test -f home/modules/ai/options.nix
  test -f home/modules/programs/hyprland/hyprland.nix
  test -f home/modules/programs/hyprland/keybinds.nix
  test -f home/modules/environment/compositor.nix
  test -f home/modules/environment/shortcuts.nix
  test -f home/modules/programs/gaming/prismlauncher.nix

  touch $out
''
