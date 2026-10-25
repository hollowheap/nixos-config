{ ... }:

{
  imports = [
    ../../boot/grub.nix
    ../../boot/kernel.nix
    ../../boot/secure-boot.nix
    ../../boot/tpm.nix
  ];
}
