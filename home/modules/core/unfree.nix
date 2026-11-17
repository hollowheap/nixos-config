{config, lib, ...}: {
  options.unfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = import ../../../lib/unfree.nix;
    description = "Package names allowed to build with an unfree license.";
  };

  config.nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) config.unfreePackages;
}
