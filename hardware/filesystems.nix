_:

{
  fileSystems = {
    "/".options = [
      "compress=zstd"
      "noatime"
    ];
    "/home".options = [
      "compress=zstd"
      "noatime"
    ];
    "/nix".options = [
      "compress=zstd"
      "noatime"
    ];
    "/var/log" = {
      options = [
        "compress=zstd"
        "noatime"
      ];
      neededForBoot = true;
    };
  };

  zramSwap.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
    limit = "50M";
  };
}
