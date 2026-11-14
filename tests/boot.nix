{
  pkgs,
  src,
}:
pkgs.runCommand "check-boot" {
  nativeBuildInputs = [ pkgs.ripgrep ];
} ''
  set -euo pipefail
  cd ${src}

  no_match() {
    local rc=0
    rg "$@" || rc=$?
    [ "$rc" -eq 1 ]
  }

  rg -q 'timeout = 10' boot/grub.nix
  rg -q 'configurationLimit = 10' boot/grub.nix
  no_match -q 'useOSProber' boot/grub.nix
  no_match -q 'enableCryptodisk' boot/grub.nix

  rg -q -- '-delete-older-than 14d' modules/system/nix.nix
  no_match -q 'optimise = ' modules/system/nix.nix
  rg -q 'min-free = "5G"' modules/system/nix.nix

  rg -q 'sbctl' modules/system/packages.nix
  rg -q 'double-minegrub-menu.nixosModules.default' flake/default.nix
  rg -q 'enable = true;' boot/minegrub.nix
  test ! -e pkgs/double-minegrub-menu.nix

  no_match -q 'shell_on_fail' boot/kernel.nix
  no_match -q 'rd.udev.log_level' boot/kernel.nix
  no_match -q 'initrd.verbose' boot/kernel.nix
  no_match -q 'dm-snapshot' boot/tpm.nix
  no_match -q 'tpm_tis' boot/tpm.nix
  rg -q '/var/lib/sbctl/keys/db/db.key' boot/secure-boot.nix
  test -f pkgs/install-host.nix
  test -f pkgs/luks-enroll.nix

  touch $out
''
