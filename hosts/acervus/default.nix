{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ../../modules
    ../../profiles/laptop
    ../../hardware/cpu.nix
    ../../hardware/filesystems.nix
    ../../hardware/hybrid-gpu.nix
    ../../hardware/wifi.nix
  ];

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  systemd.sleep.settings.Sleep.AllowSuspend = "no";
}
