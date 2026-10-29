{ config, pkgs, ... }:
{
  programs = {
    eza.enable = true;
    ripgrep.enable = true;
    fd.enable = true;
    fzf = {
      enable = true;
      tmux = {
        enableShellIntegration = true;
        shellIntegrationOptions = [
          "-w"
          "75%"
          "-h"
          "40%"
          "-x"
          "W"
          "-y"
          "W"
        ];
      };
      defaultOptions = [
        "--tmux=bottom,40%"
        "--layout=reverse"
        "--border=rounded"
        "--prompt='❯ '"
        "--marker='❯'"
        "--pointer='❯'"
      ];
      historyWidget.options = [
        "--border-label=' History '"
        "--border-label-pos=0"
        "--prompt=' History ❯ '"
      ];
      fileWidget.options = [
        "--border-label=' Files '"
        "--border-label-pos=0"
        "--prompt=' Files ❯ '"
        "--preview='if [ -d {} ]; then ${pkgs.eza}/bin/eza --tree --level=2 --color=always {}; else ${pkgs.bat}/bin/bat --color=always --style=numbers --line-range=:300 {}; fi'"
        "--preview-window='right:55%,border-rounded'"
      ];
      changeDirWidget.options = [
        "--border-label=' Directories '"
        "--border-label-pos=0"
        "--prompt=' Directories ❯ '"
        "--preview='${pkgs.eza}/bin/eza --tree --level=2 --color=always {}'"
        "--preview-window='right:50%,border-rounded'"
      ];
    };
    jq.enable = true;

    delta = {
      enable = true;
      enableGitIntegration = true;
      options.syntax-theme = "wallust";
    };
  };

  programs.wallust.settings.templates.delta = {
    template = "delta.gitconfig";
    target = "${config.home.homeDirectory}/.config/delta/wallust.gitconfig";
  };

  programs.git.includes = [
    {
      path = "${config.home.homeDirectory}/.config/delta/wallust.gitconfig";
    }
  ];

  home.packages = with pkgs; [
    harlequin
    tdf
  ];
}
