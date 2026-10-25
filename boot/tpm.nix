{ ... }:

{
  users.adminExtraGroups = [ "tss" ];

  boot.initrd = {
    # Modules needed for encrypted boot with tpm unlock
    kernelModules = [
      "dm-snapshot"
      "cryptd"
    ];
    availableKernelModules = [ "tpm_tis" ];

    luks.devices."crypted".crypttabExtraOpts = [
      "tpm2-device=auto"
      "tpm2-measure-pcr=yes"
    ];

    systemd = {
      tpm2.enable = true;
      tpm2.pcrphases.enable = true;
    };
  };
}
