{ lib, pkgs, ... }:

let
  inherit (lib.attrsets) genAttrs;
  adminUsers = [ "hollowheap" ];
  users = [
    "steve"
  ]
  ++ adminUsers;

  baseUserConfig = {
    isNormalUser = true;
    initialPassword = "";
  };

  adminUserConfig = {
    extraGroups = [
      "wheel"
      "tss"
      "networkmanager"
      "i2c"
      "video"
      "podman"
    ];
  }
  // baseUserConfig;

  usersConfig = genAttrs users (_: baseUserConfig);

  adminsConfig = genAttrs adminUsers (_: adminUserConfig);
in
{
  users = {
    users = usersConfig // adminsConfig;
    defaultUserShell = pkgs.zsh;
    inherit adminUsers;
  };
}
