{ pkgs, ... }:

{
  boot.kernelModules = [ "coretemp" ];

  hardware = {
    cpu.intel = {
      updateMicrocode = true;
      microcodePackage = pkgs."microcode-intel";
      npu.enable = true;
    };
    acpilight.enable = true;
  };
}
