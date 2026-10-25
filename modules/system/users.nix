{ config, lib, pkgs, ... }:

let
  inherit (lib.attrsets) genAttrs;
  adminUsers = [ "hollowheap" ];
  # steve is a non-admin test user.
  users = [
    "steve"
  ]
  ++ adminUsers;

  baseUserConfig = {
    isNormalUser = true;
    initialPassword = "";
  };

  adminUserConfig = {
    extraGroups = [ "wheel" ] ++ config.users.adminExtraGroups;
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
