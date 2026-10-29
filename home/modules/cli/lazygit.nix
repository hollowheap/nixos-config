{ config, ... }:
{
  programs.lazygit = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      git.diffRenderers = [
        {
          command = "delta --paging=never";
        }
      ];
    };
  };

  home.sessionVariables = {
    LG_CONFIG_FILE = "${config.xdg.configHome}/lazygit/config.yml,${config.xdg.configHome}/lazygit/theme.yml";
  };

  programs.wallust.settings.templates.lazygit = {
    template = "lazygit.yml";
    target = "${config.home.homeDirectory}/.config/lazygit/theme.yml";
  };
}
