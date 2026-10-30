{ config, lib, ... }:
let
  localAccountsFile = ./accounts.local.nix;
  localAccounts =
    if builtins.pathExists localAccountsFile then
      import localAccountsFile
    else
      { };
in
{
  accounts.email = {
    maildirBasePath = "${config.home.homeDirectory}/.mail";
    accounts = lib.optionalAttrs (localAccounts != { }) {
      personal = {
        primary = true;
        gpg = {
          key = "41F93F1724EDF2D022E696E86B2A3C5D49EE0523";
          signByDefault = true;
        };
        thunderbird = {
          enable = true;
          profiles = [ "default" ];
        };
      } // localAccounts;
    };
  };
}
