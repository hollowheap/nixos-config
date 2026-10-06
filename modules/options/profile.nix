{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.profile = mkOption {
    type = types.enum [
      "desktop"
      "laptop"
    ];
    description = "Device profile role.";
  };
}
