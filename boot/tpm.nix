{ ... }:

{
  users.adminExtraGroups = [ "tss" ];

  boot.initrd = {
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
