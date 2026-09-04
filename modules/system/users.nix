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
      ];
    }
    // baseUserConfig;
  };
in
{
  users.users = usersConfig;
  users.defaultUserShell = pkgs.zsh;
}
