{ pkgs, ... }:

{
  programs = {
    eza.enable = true;
    ripgrep.enable = true;
    fd.enable = true;
    jq.enable = true;

    fzf = {
      enable = true;
      defaultOptions = [
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
      ];
      changeDirWidget.options = [
        "--border-label=' Directories '"
        "--border-label-pos=0"
        "--prompt=' Directories ❯ '"
      ];
    };
  };

  home.packages = with pkgs; [
    harlequin
    tdf
  ];
}
