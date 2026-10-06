{
  inputs,
  config,
  lib,
  ...
}:

let
  isDesktop = config.profile == "desktop";
in
{
  sops = {
    defaultSopsFile = inputs.self + "/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "wireless_env" = {
        restartUnits = [ "NetworkManager.service" ];
      };
    }
    // lib.optionalAttrs isDesktop {
      "duckdns_password" = {
        restartUnits = [ "ddclient.service" ];
      };
    };
  };
}
