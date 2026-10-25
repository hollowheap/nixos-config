{ pkgs, lib, ... }:
let
  inherit (lib) mkEnableOption mkOption;
  inherit (lib.types) str;
in
{
  options.desktop = {
    touch = mkEnableOption "touchscreen compositor support";
    hdr = mkEnableOption "HDR compositor preference";
    nixpkgsVersion = mkOption {
      type = str;
      readOnly = true;
      default = pkgs.lib.version;
      description = "Nixpkgs version backing the Home Manager package set.";
    };
  };
}
