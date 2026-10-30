{ config, pkgs, ... }:

{
  time.timeZone = "Asia/Singapore";

  i18n.defaultLocale = "en_SG.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_SG.UTF-8";
    LC_IDENTIFICATION = "en_SG.UTF-8";
    LC_MEASUREMENT = "en_SG.UTF-8";
    LC_MONETARY = "en_SG.UTF-8";
    LC_NAME = "en_SG.UTF-8";
    LC_NUMERIC = "en_SG.UTF-8";
    LC_PAPER = "en_SG.UTF-8";
    LC_TELEPHONE = "en_SG.UTF-8";
    LC_TIME = "en_SG.UTF-8";
  };

  console = {
    earlySetup = true;
    packages = [ pkgs.terminus_font ];
    font = "Lat2-Terminus16";
    keyMap = config.desktop.input.layout;
  };

  documentation = {
    doc.enable = false; # Remove generic 'doc' folders
    nixos.enable = false; # Remove NixOS-specific HTML docs
  };
}
