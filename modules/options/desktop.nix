{ lib, ... }:
let
  inherit (lib) mkEnableOption;
in
{
  options.desktop = {
    touch = mkEnableOption "touchscreen support";
    hdr = mkEnableOption "HDR display support";
  };
}
