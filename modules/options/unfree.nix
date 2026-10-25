{ lib, ... }:
let
  inherit (lib) mkOption;
  inherit (lib.types) listOf str;
in
{
  options.unfreePackages = mkOption {
    type = listOf str;
    default = [ ];
    description = "Package names allowed despite unfree licenses; modules append their own names.";
  };
}
