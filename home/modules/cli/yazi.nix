{ config, ... }:
{
  programs.yazi = {
    enable = true;
    theme.flavor.use = "wallust";
  };

  programs.wallust.settings.templates.yazi = {
    template = "flavor.toml";
    target = "${config.xdg.configHome}/yazi/flavors/wallust.yazi/flavor.toml";
  };
}
