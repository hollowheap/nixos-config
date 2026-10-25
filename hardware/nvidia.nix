{ config, pkgs, ... }:

{
  unfreePackages = [
    "nvidia-kernel-modules"
    "nvidia-settings"
    "nvidia-x11"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = false;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    package = config.boot.kernelPackages.nvidiaPackages.latest;
  };

  hardware.graphics.extraPackages = [ pkgs.nvidia-vaapi-driver ];

  boot = {
    initrd.kernelModules = [
      "nvidia"
      "nvidia_uvm"
      "nvidia_drm"
      "nvidia_modeset"
    ];
    blacklistedKernelModules = [ "nouveau" ];
    kernelParams = [
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_UsePageAttributeTable=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia_modeset.disable_vrr_memclk_switch=1"
      "nouveau.modeset=0"
    ];
  };
}
