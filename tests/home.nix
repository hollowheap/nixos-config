{ pkgs, src }:
pkgs.runCommand "check-home" {
  nativeBuildInputs = with pkgs; [
    findutils
    gnugrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  test -f home/home.nix
  test -f home/cli.nix
  test -f home/gui.nix
  test -f home/apps/gaming/prismlauncher.nix
  test -f home/apps/gui.nix
  test -f home/apps/gui/ghostty.nix
  test -f home/apps/gui/zen-browser.nix
  test -f home/cli/zsh.nix
  test -f home/cli/tools.nix
  test -f home/cli/starship.nix
  test -f home/cli/tmux.nix
  test -f home/cli/wallust.nix
  test -f home/cli/opencode.nix
  test -f home/cli/ai-options.nix

  ! grep -Rq "prismlauncher" home/cli
  ! grep -Rq "home/gui" home/cli
  grep -Rq "launchApp" home/cli
  grep -Rq "defaultApps" home/cli
  grep -q "useGlobalPkgs = false" roles/desktop/home/default.nix

  touch $out
''
