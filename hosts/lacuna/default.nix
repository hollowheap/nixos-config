{ pkgs, ... }:

{
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
    ./hardware.nix
    ./boot.nix
    ../../modules
    ../../profiles/laptop
    ../../roles/desktop/system
    ../../roles/server/system
  ];

  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    vpl-gpu-rt
    intel-compute-runtime
  ];

  networking.firewall.interfaces.wlan0.allowedTCPPorts = [
    1883
    8083
    8090
  ];

  # boot.kernelParams = [ "i915.enable_guc=3" ];
}
