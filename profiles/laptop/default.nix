{ config, lib, ... }:

{
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.thermald.enable = true;

  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkDefault "suspend";
    HandleLidSwitchExternalPower = lib.mkDefault "suspend";
  };

  systemd.services.systemd-logind.reloadTriggers = [
    config.environment.etc."systemd/logind.conf".source
  ];
}
