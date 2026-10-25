{ pkgs, ... }:

{
  boot.kernelModules = [ "coretemp" ];

  hardware = {
    cpu.intel = {
      updateMicrocode = true;
      microcodePackage = pkgs."microcode-intel";
    };
    acpilight.enable = true;
  };
}
