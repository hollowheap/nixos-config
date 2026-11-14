# Placeholder until `nixos-generate-config --no-filesystems` runs on acervus during installation.
{ lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "uas"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-intel" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
