{ pkgs, ... }:

{
  boot.kernelModules = [ "coretemp" ];

  hardware = {
    enableRedistributableFirmware = true;
    cpu.intel = {
      updateMicrocode = true;
      microcodePackage = pkgs."microcode-intel";
      npu.enable = true;
    };
    acpilight.enable = true;
  };
}
