{ config, ... }:
{
  home.sessionVariables._ZO_ECHO = "1";

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };
}
