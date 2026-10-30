{ config, pkgs, ... }:
{
  home.sessionVariables.MANPAGER = "batman";

  programs.bat = {
    enable = true;
    config = {
      theme = "wallust";
    };
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      batgrep
      batpipe
      batwatch
      prettybat
    ];
  };

  programs.wallust.settings = {
    templates.bat = {
      template = "bat.tmTheme";
      target = "${config.xdg.configHome}/bat/themes/wallust.tmTheme";
    };
    hooks.bat = "${pkgs.bat}/bin/bat cache --build 2>/dev/null || true";
  };
}
