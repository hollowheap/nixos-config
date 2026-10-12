{ ... }:

{
  services.power-profiles-daemon.enable = true;
  hardware.nvidia.powerManagement.finegrained = true;
}
