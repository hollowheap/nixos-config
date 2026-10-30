{ pkgs, ... }:

{
  security.rtkit.enable = true;

  services = {
    printing.enable = true;

    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    greetd.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    usbmuxd.enable = true;
    colord.enable = true;
  };

  hardware.sane.enable = true;

  programs = {
    gamemode.enable = true;
    obs-studio.enableVirtualCamera = true;
  };

  environment.systemPackages = with pkgs; [
    simple-scan
    system-config-printer
  ];
}