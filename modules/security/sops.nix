{ inputs, ... }:

{
  sops = {
    defaultSopsFile = inputs.self + "/secrets.yaml";
    defaultSopsFormat = "yaml";
    useSystemdActivation = true;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    secrets = {
      "wireless_env" = {
        restartUnits = [ "NetworkManager.service" ];
      };
    };
  };
}
