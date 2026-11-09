{ ... }:

{
  boot.loader = {
    timeout = 10;
    efi.canTouchEfiVariables = true;

    grub = {
      enable = true;
      configurationLimit = 10;
      device = "nodev";
      efiSupport = true;
    };
  };
}
