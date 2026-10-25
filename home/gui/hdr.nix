{ config, lib, ... }:

{
  wayland.windowManager.hyprland.settings = lib.mkIf config.desktop.hdr {
    quirks.prefer_hdr = 1;
  };
}
