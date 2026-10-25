{ ... }:

{
  boot.loader = {
    timeout = 3;
    efi.canTouchEfiVariables = true;

    grub = {
      enable = true;
      configurationLimit = 3;
      device = "nodev";
      efiSupport = true;
      enableCryptodisk = true;
      useOSProber = true;
    };
  };
}
