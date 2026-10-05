{ inputs, ... }:

{
  sops = {
    defaultSopsFile = inputs.self + "/secrets.yaml";
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "wireless_env" = {
        restartUnits = [ "NetworkManager.service" ];
      };
      "duckdns_password" = {
        restartUnits = [ "ddclient.service" ];
      };
    };
  };
}
