{ config, ... }:

{
  hardware = {
    acpilight.enable = true;

    nvidia = {
      modesetting.enable = true;
      open = true;
      nvidiaSettings = true;

      powerManagement = {
        enable = true;
        finegrained = config.profile == "laptop";
      };
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };

    cpu.intel.updateMicrocode = true;
  };
}
