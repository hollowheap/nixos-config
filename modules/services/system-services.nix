_:

{
  services = {
    xserver.enable = false;

    printing.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    greetd.enable = true;
    openssh.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    usbmuxd.enable = true;
    colord.enable = true;
    fwupd.enable = true;
  };
}
