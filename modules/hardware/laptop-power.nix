{
  config,
  lib,
  ...
}:

let
  inherit (lib) mkIf;
  isLaptop = config.profile == "laptop";
in
{
  config = mkIf isLaptop {
    services.power-profiles-daemon.enable = true;
  };
}
