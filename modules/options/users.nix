{ lib, ... }:
let
  inherit (lib) mkOption;
  inherit (lib.types) str listOf;
in
{
  options.users = {
    adminUsers = mkOption {
      type = listOf str;
      description = "List of users that are administrators.";
    };

    adminExtraGroups = mkOption {
      type = listOf str;
      default = [ ];
      description = "Extra groups granted to every administrator; modules append their own.";
    };
  };
}
