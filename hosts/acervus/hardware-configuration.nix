# Placeholder until `nixos-generate-config` runs on acervus during installation.
{ lib, ... }:

{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Placeholder mount points until disko runs on acervus.
  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-partlabel/crypted";

  fileSystems = {
    "/" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
    };
    "/boot" = {
      device = "/dev/disk/by-partlabel/ESP";
      fsType = "vfat";
    };
    "/home" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
    };
    "/nix" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
    };
    "/var/log" = {
      device = "/dev/mapper/crypted";
      fsType = "btrfs";
    };
  };
}
