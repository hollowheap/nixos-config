{ pkgs, ... }:

{
  users.adminExtraGroups = [ "video" ];

  boot.initrd.kernelModules = [ "i915" ];
  boot.kernelParams = [ "i915.fastboot=1" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    package = pkgs.mesa;
    package32 = pkgs.pkgsi686Linux.mesa;
  };
}
