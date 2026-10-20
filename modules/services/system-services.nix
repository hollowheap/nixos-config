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
  };
}
