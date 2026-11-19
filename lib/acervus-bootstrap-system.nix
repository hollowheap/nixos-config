{ configuration, encryptedFile }:
configuration.extendModules {
  modules = [
    (
      { config, lib, ... }:
      {
        assertions = [
          {
            assertion = builtins.attrNames config.sops.secrets == [ "wireless_env" ];
            message = "The acervus bootstrap source may only provide wireless_env.";
          }
        ];
        sops.secrets.wireless_env.sopsFile = lib.mkForce encryptedFile;
      }
    )
  ];
}
