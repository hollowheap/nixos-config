{ lib, pkgs, ... }:

let
  adminUser = "hollowheap";
  users = [
    "steve"
    adminUser
  ];

  baseUserConfig = {
    isNormalUser = true;
    initialPassword = "";
  };

  usersConfig = lib.attrsets.genAttrs users (_: baseUserConfig) // {
    "${adminUser}" = {
      extraGroups = [
        "wheel"
        "tss"
        "networkmanager"
        "i2c"
        "video"
      ];
    }
    // baseUserConfig;
  };
in
{
  users.users = usersConfig;
  users.defaultUserShell = pkgs.zsh;
}
