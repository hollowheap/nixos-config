{ config, pkgs, ... }:
{
  programs.yazi = {
    enable = true;
    theme.flavor = {
      dark = "wallust";
      light = "wallust";
    };
  };

  programs.wallust.settings.templates.yazi = {
    template = "flavor.toml";
    target = "${config.xdg.configHome}/yazi/flavors/wallust.yazi/flavor.toml";
  };

  programs.wallust.settings.templates.yazi-tmtheme = {
    template = "bat.tmTheme";
    target = "${config.xdg.configHome}/yazi/flavors/wallust.yazi/tmtheme.xml";
  };

  home.packages = with pkgs; [
    ffmpeg
    poppler-utils
  ];
}
