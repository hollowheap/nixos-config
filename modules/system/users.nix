{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.attrsets) genAttrs;
  adminUsers = ["hollowheap"];
  # steve is a non-admin test user.
  users =
    [
      "steve"
    ]
    ++ adminUsers;

  gpgAuthKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGmWse+nAkLVADDX/hM3wO8ywLuIBXTyLj3ccor7r8NS openpgp:0xE631B8B9";

  baseUserConfig = {
    isNormalUser = true;
    initialPassword = "";
    openssh.authorizedKeys.keys = [gpgAuthKey];
  };

  adminUserConfig =
    {
      extraGroups = ["wheel"] ++ config.users.adminExtraGroups;
    }
    // baseUserConfig;

  usersConfig = genAttrs users (_: baseUserConfig);

  adminsConfig = genAttrs adminUsers (_: adminUserConfig);
in {
  users = {
    mutableUsers = false;
    users = usersConfig // adminsConfig;
    defaultUserShell = pkgs.zsh;
    inherit adminUsers;
  };
}
