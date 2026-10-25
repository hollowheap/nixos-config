{ config, pkgs, ... }:
{
  programs.btop = {
    enable = true;
    package = pkgs.btop-cuda;
  };

  programs.wallust.settings = {
    templates.btop = {
      template = "btop.theme";
      target = "${config.home.homeDirectory}/.config/btop/themes/wallust.theme";
    };
    hooks.btop = "${pkgs.procps}/bin/pkill -SIGUSR2 -x btop || true";
  };
}
