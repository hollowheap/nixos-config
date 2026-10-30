{ config, pkgs, ... }:
{
  programs.btop = {
    enable = true;
    package = pkgs.btop-cuda;
    settings = {
      color_theme = "wallust";
      vim_keys = true;
    };
  };

  programs.wallust.settings = {
    templates.btop = {
      template = "btop.theme";
      target = "${config.xdg.configHome}/btop/themes/wallust.theme";
    };
    hooks.btop = "${pkgs.procps}/bin/pkill -SIGUSR2 -x btop || true";
  };
}
