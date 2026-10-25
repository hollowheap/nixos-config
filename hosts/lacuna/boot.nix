{ ... }:

{
  imports = [
    ../../boot/grub.nix
    ../../boot/kernel.nix
    ../../boot/minegrub.nix
    ../../boot/plymouth.nix
    ../../boot/secure-boot.nix
    ../../boot/tpm.nix
  ];
}
