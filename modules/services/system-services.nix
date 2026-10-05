{ ... }:

{
  services = {
    xserver.enable = false;
    xserver.videoDrivers = [ "nvidia" ];

    printing.enable = true;

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    greetd.enable = true;
    openssh.enable = true;
    upower.enable = true;
  };
}
