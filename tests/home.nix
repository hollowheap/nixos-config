{ pkgs, src }:
pkgs.runCommand "check-home" {
  nativeBuildInputs = with pkgs; [
    findutils
    ripgrep
  ];
} ''
  set -euo pipefail
  cd ${src}

  no_match() {
    local rc=0
    rg "$@" || rc=$?
    [ "$rc" -eq 1 ]
  }

  test -f home/hollowheap.nix
  test -f home/modules/programs/nvim/lsp.nix
  rg -q "yamllint" home/modules/programs/nvim/lsp.nix
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
  rg -q "./nvim/diagrams.nix" home/modules/programs/nvim.nix
  rg -q "diagram.nvim" flake/default.nix

  ! test -e home/cli.nix
  ! test -e home/gui.nix
  ! test -e home/modules/options
  rg -q "inputs.import-tree ./modules" home/hollowheap.nix
  rg -q "hollowheap/opal" flake.nix
  rg -q "hollowheap/iridescent" flake.nix
  rg -q -F 'inputs.opal.outPath + "/skills"' home/modules/ai/skills.nix
  rg -q -F 'inputs.iridescent + "/skills"' home/modules/ai/skills.nix
  rg -q -F 'inputs.docmd + "/skills"' home/modules/ai/skills.nix
  rg -q "splitFrontmatter" lib/ai-skills.nix
  rg -q "readReferenceFiles" lib/ai-skills.nix
  ! test -e pkgs/ui-probe.nix
  ! test -e assets/skills/opal
  rg -q "inputs.opal.packages" home/modules/cli/utilities.nix
  rg -q "libnotify" home/modules/cli/utilities.nix
  rg -q "programs.claude-code" home/modules/programs/claude-code.nix
  rg -q 'systemPrompt' home/modules/programs/claude-code.nix
  rg -q 'append-system-prompt-file' home/modules/programs/claude-code.nix
  rg -q "web-dispatcher" home/modules/programs/default-apps.nix
  rg -q "music.youtube.com" home/modules/programs/default-apps.nix
  rg -q "username = \"hollowheap\"" home/hollowheap.nix
  rg -q "desktop.touch = true" home/hollowheap.nix
  rg -q "readDir ../home" flake/default.nix
  rg -q "genAttrs homeUserNames" flake/default.nix
  rg -q "config.desktop.primaryScale" home/modules/programs/hyprland/hyprland.nix
  rg -q "focus_on_activate" home/modules/programs/hyprland/hyprland.nix
  rg -q "bind = map mkArgs" home/modules/programs/hyprland/keybinds.nix
  rg -q "desktop.touchscreen" home/modules/environment/touch.nix
  rg -q "desktop.touchscreen.devices" home/modules/programs/hyprland/hyprland.nix
  rg -q "toggle-touch-keyboard" home/modules/environment/touch.nix
  no_match -q "wvkbd" home/modules/environment/touch.nix
  no_match -q "LIBVA_DRIVER_NAME" home/modules/environment/session.nix
  rg -q "LIBVA_DRIVER_NAME" hardware/nvidia.nix
  rg -q "desktop.actions" home/modules/programs/hyprland/keybinds.nix
  rg -q "desktop.windowRules" home/modules/programs/hyprland/hyprland.nix
  rg -q "zen-auth-popups" home/modules/programs/gui/zen-browser.nix
  rg -q "screenshare-picker" home/modules/environment/rules.nix
  rg -q "pi.mode" home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "thinking"' home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "cost"' home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "usage"' home/modules/programs/pi-coding-agent.nix
  no_match -q '"budgets"' home/modules/programs/pi-coding-agent.nix
  no_match -q 'type = "clock"' home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "version"' home/modules/programs/pi-coding-agent.nix
  no_match -q 'hollowpi-dashboard' home/modules/programs/pi-coding-agent.nix
  rg -q 'wallust/sequences' pkgs/hollowpi-colorscript.nix
  rg -q 'phase' pkgs/hollowpi-colorscript.nix
  no_match -q '38;2;94;129;172' pkgs/hollowpi-colorscript.nix
  rg -q 'menu no' home/modules/terminal/zsh.nix
  rg -q 'matcher-list' home/modules/terminal/zsh.nix
  rg -q -F '"$character"' home/modules/terminal/starship.nix
  rg -q -F '{#90}' home/modules/cli/fastfetch.nix
  rg -q -F '{#30}' home/modules/cli/fastfetch.nix
  no_match -F -q '{#39}' home/modules/cli/fastfetch.nix
  rg -q 'ZLE_RPROMPT_INDENT = "0"' home/modules/terminal/zsh.nix
  rg -q -e "-builtin:tool-search" home/modules/programs/pi-coding-agent.nix
  rg -q -e "-builtin:mcp" home/modules/programs/pi-coding-agent.nix
  rg -q -e "-builtin:llama.cpp" home/modules/programs/pi-coding-agent.nix
  rg -q "bind C-g send-keys C-g" home/modules/terminal/tmux.nix
  rg -q "bind l send-keys l" home/modules/terminal/tmux.nix
  rg -q "@continuum-save-interval '5'" home/modules/terminal/tmux.nix
  rg -q "@resurrect-strategy-nvim 'session'" home/modules/terminal/tmux.nix
  rg -q "continuum_save.sh" home/modules/terminal/tmux.nix
  rg -q 'List all key bindings' home/modules/terminal/tmux.nix
  rg -q 'list-keys -T prefix' home/modules/terminal/tmux.nix
  rg -q "unbind -q g" home/modules/terminal/tmux.nix
  rg -q "bind -n C-g display-popup" home/modules/terminal/tmux.nix
  rg -q "bind -n C-y display-popup" home/modules/terminal/tmux.nix
  rg -q "bind -n C-b display-popup" home/modules/terminal/tmux.nix
  no_match -q "bind C-g display-popup" home/modules/terminal/tmux.nix
  no_match -q "bind g display-popup" home/modules/terminal/tmux.nix
  no_match -q "bind y display-popup" home/modules/terminal/tmux.nix
  no_match -q "bind b display-popup" home/modules/terminal/tmux.nix
  no_match -q "bind t display-popup" home/modules/terminal/tmux.nix
  rg -q "bind -n C-p previous-window" home/modules/terminal/tmux.nix
  rg -q ']4;7;#e0e0e0' assets/wallust-templates/sequences
  rg -q ']4;8;#2e2e2e' assets/wallust-templates/sequences
  rg -q 'FZF_DEFAULT_OPTS_FILE' home/modules/cli/utilities.nix
  rg -q 'fzf/colors' home/modules/cli/utilities.nix
  rg -q 'template = "fzf"' home/modules/programs/wallust.nix
  rg -q 'pkill -USR2 -x opencode' home/modules/programs/wallust.nix
  rg -q 'theme.name = "wallust"' home/modules/programs/opencode.nix
  rg -q '.codex/themes/wallust.tmTheme' home/modules/programs/codex.nix
  no_match -q '.config/codex/themes' home/modules/programs/codex.nix
  rg -q 'template = "opencode.json"' home/modules/programs/opencode.nix
  test -f assets/wallust-templates/opencode.json
  rg -q -F '"syntaxKeyword": "{{color4}}"' assets/wallust-templates/opencode.json
  rg -q -F '"text": "#e0e0e0"' assets/wallust-templates/opencode.json
  rg -q -F '"border": "#2e2e2e"' assets/wallust-templates/opencode.json
  test -f assets/wallust-templates/fzf
  rg -q -F -- '--color=fg:#e0e0e0' assets/wallust-templates/fzf
  no_match -q '\{\{\s*color(7|8)\b' assets/wallust-templates
  for template in bat.tmTheme btop.theme crush.json delta.gitconfig flavor.toml fzf ghostty lazygit.yml nvim-colors.lua opencode.json sequences; do
    test -f "assets/wallust-templates/$template"
  done
  rg -q 'template = "bat.tmTheme"' home/modules
  rg -q 'template = "btop.theme"' home/modules
  rg -q 'template = "crush.json"' home/modules
  rg -q 'template = "delta.gitconfig"' home/modules
  rg -q 'template = "flavor.toml"' home/modules
  rg -q 'template = "ghostty"' home/modules
  rg -q 'template = "lazygit.yml"' home/modules
  rg -q 'template = "nvim-colors.lua"' home/modules
  rg -q 'template = "opencode.json"' home/modules
  rg -q 'hooks\.bat' home/modules
  rg -q 'hooks\.btop' home/modules
  rg -q 'hooks\.ghostty' home/modules
  rg -q 'hooks\.nvim' home/modules
  rg -q 'pkill -USR2 -x opencode' home/modules
  rg -q "detectContrast" lib/color.nix
  rg -q -F "inherit (color) detectContrast" home/modules/styles/pills.nix
  no_match -q 'prev_fg|prev_bg' home/modules/styles/pills.nix
  no_match -q "wayland.windowManager.hyprland" home/modules/environment/touch.nix
  rg -q "config.desktop.touchscreen" home/modules/programs/hyprland/hyprland.nix
  rg -q "config.desktop.compositor" home/modules/programs/hyprland/hyprland.nix
  no_match -q "bind = map mkArgs" home/modules/programs/hyprland/hyprland.nix
  rg -q "../../../lib/hyprland.nix" home/modules/programs/hyprland/keybinds.nix
  rg -q "config.desktop.primaryScale" roles/desktop/system/default.nix
  rg -q "config.desktop.fonts" home/modules/styles/fonts.nix
  no_match -q "stylix" flake.nix

  touch $out
''
