{ pkgs, src }:
pkgs.runCommand "check-home" {
  nativeBuildInputs = with pkgs; [
    findutils
    gnugrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  test -f home/hollowheap.nix
  test -f home/lib/toolchains.nix
  test -f home/modules/ai/options.nix
  test -f home/modules/ai/agents.nix
  test -f home/modules/programs/thunderbird-accounts.nix
  test -f modules/options/desktop.nix
  test -f home/modules/programs/hyprland/hyprland.nix
  test -f home/modules/programs/hyprland/keybinds.nix
  test -f home/modules/environment/touch.nix
  test -f home/modules/environment/compositor.nix
  test -f home/modules/environment/actions.nix
  test -f home/modules/environment/rules.nix
  test -f home/modules/environment/session.nix
  test -f lib/color.nix
  test -f pkgs/wvkbd-split.nix
  test -f home/modules/services/playerctld.nix
  test -f home/modules/services/udiskie.nix
  ! test -e home/modules/services/playerctld-udiskie.nix
  ! test -e home/modules/core/env.nix
  test -f home/modules/programs/default-apps.nix
  test -f home/modules/programs/default-apps-options.nix
  test -f home/modules/programs/gui/pear-desktop-options.nix
  test -f home/modules/programs/gui/pear-desktop.nix
  test -f home/modules/programs/gaming/prismlauncher.nix
  test -f home/modules/programs/codex.nix
  test -f home/modules/cli/gpg.nix
  test -f home/modules/services/auth-agents.nix
  test -f home/modules/terminal/zsh.nix
  test -f home/modules/programs/wallust.nix
  test -f home/modules/programs/nvim/diagrams.nix
  grep -q "./nvim/diagrams.nix" home/modules/programs/nvim.nix
  grep -q "diagram.nvim" flake/default.nix

  ! test -e home/cli.nix
  ! test -e home/gui.nix
  ! test -e home/modules/options
  grep -q "inputs.import-tree ./modules" home/hollowheap.nix
  grep -q "username = \"hollowheap\"" home/hollowheap.nix
  grep -q "desktop.touch = true" home/hollowheap.nix
  grep -q "readDir ../home" flake/default.nix
  grep -q "genAttrs homeUserNames" flake/default.nix
  grep -q "config.desktop.primaryScale" home/modules/programs/hyprland/hyprland.nix
  grep -q "bind = map mkArgs" home/modules/programs/hyprland/keybinds.nix
  grep -q "desktop.touchscreen" home/modules/environment/touch.nix
  grep -q "desktop.touchscreen.devices" home/modules/programs/hyprland/hyprland.nix
  grep -q "toggle-touch-keyboard" home/modules/environment/touch.nix
  ! grep -q "wvkbd" home/modules/environment/touch.nix
  ! grep -q "LIBVA_DRIVER_NAME" home/modules/environment/session.nix
  grep -q "LIBVA_DRIVER_NAME" hardware/nvidia.nix
  grep -q "desktop.actions" home/modules/programs/hyprland/keybinds.nix
  grep -q "desktop.windowRules" home/modules/programs/hyprland/hyprland.nix
  grep -q "zen-auth-popups" home/modules/programs/gui/zen-browser.nix
  grep -q "screenshare-picker" home/modules/environment/rules.nix
  grep -q "pi.mode" home/modules/programs/pi-coding-agent.nix
  grep -q -- "-builtin:tool-search" home/modules/programs/pi-coding-agent.nix
  grep -q -- "-builtin:mcp" home/modules/programs/pi-coding-agent.nix
  grep -q -- "-builtin:llama.cpp" home/modules/programs/pi-coding-agent.nix
  grep -q "bind C-g send-keys C-g" home/modules/terminal/tmux.nix
  grep -q "bind l send-keys l" home/modules/terminal/tmux.nix
  grep -q "@continuum-save-interval '15'" home/modules/terminal/tmux.nix
  grep -q "@resurrect-strategy-nvim 'session'" home/modules/terminal/tmux.nix
  grep -q "continuum_save.sh" home/modules/terminal/tmux.nix
  grep -q 'List all key bindings' home/modules/terminal/tmux.nix
  grep -q 'list-keys -T prefix' home/modules/terminal/tmux.nix
  grep -q "unbind -q g" home/modules/terminal/tmux.nix
  grep -q "bind -n C-g display-popup" home/modules/terminal/tmux.nix
  grep -q "bind -n C-y display-popup" home/modules/terminal/tmux.nix
  grep -q "bind -n C-b display-popup" home/modules/terminal/tmux.nix
  ! grep -q "bind C-g display-popup" home/modules/terminal/tmux.nix
  ! grep -q "bind g display-popup" home/modules/terminal/tmux.nix
  ! grep -q "bind y display-popup" home/modules/terminal/tmux.nix
  ! grep -q "bind b display-popup" home/modules/terminal/tmux.nix
  ! grep -q "bind t display-popup" home/modules/terminal/tmux.nix
  ! grep -q "bind -n C-p" home/modules/terminal/tmux.nix
  grep -q ']4;7;#e0e0e0' assets/wallust-templates/sequences
  grep -q ']4;8;#2e2e2e' assets/wallust-templates/sequences
  grep -q "detectContrast" lib/color.nix
  grep -q "inherit (color) detectContrast" home/modules/styles/pills.nix
  ! grep -q "prev_fg\|prev_bg" home/modules/styles/pills.nix
  ! grep -q "wayland.windowManager.hyprland" home/modules/environment/touch.nix
  grep -q "config.desktop.touchscreen" home/modules/programs/hyprland/hyprland.nix
  grep -q "config.desktop.compositor" home/modules/programs/hyprland/hyprland.nix
  ! grep -q "bind = map mkArgs" home/modules/programs/hyprland/hyprland.nix
  grep -q "../../../lib/hyprland.nix" home/modules/programs/hyprland/keybinds.nix
  grep -q "config.desktop.primaryScale" roles/desktop/system/default.nix
  grep -q "config.desktop.primaryOutput" roles/desktop/system/default.nix
  grep -q "config.desktop.fonts" home/modules/styles/fonts.nix
  ! grep -q "stylix" flake.nix

  touch $out
''
