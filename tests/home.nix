{
  pkgs,
  src,
}:
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
  rg -q "yamllint" home/modules/core/toolchain.nix
  test -f pkgs/hollow-nv-colorscript.nix
  rg -q "hollow-nv-colorscript --animate" home/modules/programs/nvim/snacks.nix
  test -f home/modules/ai/options.nix
  test -f home/modules/ai/agents.nix
  test -f .artifacts/REPOMAP.md
  ! test -e pkgs/repomap.nix
  ! test -e .artifacts/repomap.md
  no_match -q 'repomap' home/modules/ai/hooks.nix
  no_match -q 'repomap' home/modules/programs/kiro-cli.nix
  no_match -q 'repomap' .artifacts/ARCHITECTURE.md
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
  ! test -e home/modules/programs/gui/pear-desktop-options.nix
  ! test -e home/modules/programs/gui/pear-desktop.nix
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
  rg -q "renderGroupedHooks" home/modules/programs/claude-code.nix
  rg -q 'hooksForWith \{ inherit dropHooks; \}' home/lib/ai-render.nix
  for adapter in opencode claude-code kiro-cli; do
    rg -q 'dropHooks = \[\s*"pre-tool"\s*\]' home/modules/programs/$adapter.nix
  done
  for adapter in codex antigravity crush hermes; do
    no_match -q 'dropHooks' home/modules/programs/$adapter.nix
  done
  rg -q 'pre-tool' home/modules/ai/hooks.nix
  rg -q 'ai-git-policy' home/modules/ai/hooks.nix
  rg -q "music.youtube.com" home/modules/programs/gui/zen-browser.nix
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
  rg -q "fingers = 2;" home/modules/environment/touch.nix
  no_match -q "wvkbd" home/modules/environment/touch.nix
  no_match -q "LIBVA_DRIVER_NAME" home/modules/environment/session.nix
  rg -q "LIBVA_DRIVER_NAME" hardware/nvidia.nix
  rg -q "desktop.actions" home/modules/programs/hyprland/keybinds.nix
  rg -q "desktop.windowRules" home/modules/programs/hyprland/hyprland.nix
  rg -q "zen-auth-popups" home/modules/programs/gui/zen-browser.nix
  rg -q "screenshare-picker" home/modules/environment/rules.nix
  rg -q "pi.mode" home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "agent"' home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "model-effort"' home/modules/programs/pi-coding-agent.nix
  no_match -q 'statusline-model-effort\.ts' home/modules/programs/pi-coding-agent.nix
  no_match -q 'SYSTEM\.md' home/modules/programs/pi-coding-agent.nix
  rg -q 'extensions/system-prompt-docs\.ts' home/modules/programs/pi-coding-agent.nix
  rg -q 'event\.systemPromptOptions\.sections\.docs' home/modules/programs/pi-coding-agent.nix
  rg -q 'agents: \$\{concatStringsSep' home/modules/programs/pi-coding-agent.nix
  no_match -q 'pi-statusline\.json' home/modules/programs/pi-coding-agent.nix
  rg -q 'exposure = "codemode"' home/modules/ai/options.nix
  rg -q 'config.programs.mcp.servers.refero' home/modules/ai/options.nix
  rg -q 'renderMcpServers' home/lib/ai-render.nix
  rg -q 'aiRender.renderMcpServers config.programs.mcp.servers' home/modules/programs/pi-coding-agent.nix
  no_match -q 'mcpServers' home/modules/programs/pi-coding-agent.nix
  no_match -q 'defaultTools' home/modules/programs/pi-coding-agent.nix
  no_match -q 'type = "thinking"' home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "cost"' home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "usage-pct"' home/modules/programs/pi-coding-agent.nix
  rg -q -U 'extensions = \[[^]]*"agent"' home/modules/programs/pi-coding-agent.nix
  rg -q -U 'extensions = \[[^]]*"usage-pct"' home/modules/programs/pi-coding-agent.nix
  rg -q 'extensions/statusline-usage-pct\.ts' home/modules/programs/pi-coding-agent.nix
  rg -q 'statusline-common\.sh' pkgs/agy-statusline.nix
  rg -q '\.buckets' pkgs/agy-statusline.sh
  rg -q 'rate_limits' pkgs/agy-statusline.sh
  no_match -q '% rem' pkgs/agy-statusline.sh
  rg -q 'statusline-common\.sh' pkgs/claude-statusline.nix
  no_match -q 'status --porcelain' pkgs/statusline-common.sh
  rg -q '"MANUAL"' pkgs/claude-statusline.sh
  rg -q 'transcript_path' pkgs/claude-statusline.sh
  rg -q 'permissions\.defaultMode' pkgs/claude-statusline.sh
  rg -q '"EDITS"' pkgs/claude-statusline.sh
  rg -q '"EDITS"' pkgs/agy-statusline.sh
  no_match -q '"AGY"' pkgs/agy-statusline.sh
  rg -q 'claude-statusline' home/modules/programs/claude-code.nix
  rg -q 'padding = 0;' home/modules/programs/claude-code.nix
  rg -q 'mutableSettings = true;' home/modules/programs/claude-code.nix
  rg -q -F 'agents = builtins.mapAttrs mkAgent config.ai.agents;' home/modules/programs/claude-code.nix
  rg -q -F 'lib.filterAttrs (_: agent: agent.role == "primary")' home/modules/programs/claude-code.nix
  rg -q 'CLAUDE_CODE_DISABLE_BUNDLED_SKILLS' home/modules/programs/claude-code.nix
  rg -q 'CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS' home/modules/programs/claude-code.nix
  rg -q 'CLAUDE_CODE_SUBAGENT_MODEL' home/modules/programs/claude-code.nix
  no_match -q '"Agent\(general-purpose\)"' home/modules/programs/claude-code.nix
  rg -q 'Agent\(claude-code-guide\)' home/modules/programs/claude-code.nix
  rg -q 'disableArtifact = true;' home/modules/programs/claude-code.nix
  rg -q 'editorMode = "normal";' home/modules/programs/claude-code.nix
  rg -q 'verbose = true;' home/modules/programs/claude-code.nix
  rg -q 'outputStyle = "default";' home/modules/programs/claude-code.nix
  rg -q 'workflowKeywordTriggerEnabled = false;' home/modules/programs/claude-code.nix
  no_match -q 'tierModelFor "claude-code"' home/modules/programs/claude-code.nix
  no_match -q 'effortLevel\s*=' home/modules/programs/claude-code.nix
  no_match -q '"budgets"' home/modules/programs/pi-coding-agent.nix
  no_match -q 'type = "clock"' home/modules/programs/pi-coding-agent.nix
  rg -q 'type = "version"' home/modules/programs/pi-coding-agent.nix
  no_match -q 'hollowpi-dashboard' home/modules/programs/pi-coding-agent.nix
  rg -q 'wallust/sequences' pkgs/wallust-colorscript.py
  rg -q 'phase' pkgs/wallust-colorscript.py
  no_match -q '38;2;94;129;172' pkgs/hollowpi-colorscript.nix pkgs/hollowheap-colorscript.nix pkgs/wallust-colorscript.py
  no_match -q '#000000|#ffffff|#e0e0e0|#2e2e2e' pkgs/wallust-colorscript.py
  rg -q 'menu no' home/modules/terminal/zsh.nix
  rg -q 'matcher-list' home/modules/terminal/zsh.nix
  rg -q -F '"$character"' home/modules/terminal/starship.nix
  rg -q 'programs\.zsh\.envExtra' home/modules/terminal/starship.nix
  rg -q 'systemctl.*set-environment STARSHIP_CONFIG' home/modules/programs/wallust.nix
  rg -q 'backend = "full";' home/modules/programs/wallust.nix
  no_match -q 'color_space = "lchansi";' home/modules/programs/wallust.nix
  no_match -q 'palette = "ansidark16";' home/modules/programs/wallust.nix
  test -f pkgs/wallust-palette.nix
  test -f pkgs/wallust-palette.py
  no_match -q 'pillow' pkgs/wallust-palette.nix
  no_match -q 'PIL' pkgs/wallust-palette.py
  rg -q 'oklab' pkgs/wallust-palette.py
  rg -q 'drift' pkgs/wallust-palette.py
  rg -q 'def neutral' pkgs/wallust-palette.py
  rg -q '"color0": "#000000"' pkgs/wallust-palette.py
  rg -q 'IDW_POWER = 1' pkgs/wallust-palette.py
  rg -q 'def proximity' pkgs/wallust-palette.py
  rg -q 'def tier_ratio' pkgs/wallust-palette.py
  no_match -q -P 'print\((?!.*file=sys\.stderr)' pkgs/wallust-palette.py
  rg -q 'tomllib' pkgs/wallust-palette.py
  rg -q 'def run_hooks' pkgs/wallust-palette.py
  rg -q -- '--no-hooks' pkgs/wallust-palette.py
  rg -q 'angular_distance' pkgs/wallust-palette.py
  rg -q 'LIGHT_HI = 0.72' pkgs/wallust-palette.py
  rg -q 'LIGHT_LO = 0.58' pkgs/wallust-palette.py
  rg -q 'key=lambda color: color\["C"\]' pkgs/wallust-palette.py
  no_match -F -q 'color["L"] * color["C"]' pkgs/wallust-palette.py
  rg -q 'wallust-palette' home/modules/programs/noctalia.nix home/modules/programs/wallust.nix
  no_match -q 'wallust}/bin/wallust run' home/modules/programs/noctalia.nix home/modules/programs/wallust.nix
  rg -q -F '{#90}' home/modules/cli/fastfetch.nix
  rg -q -F '{#30}' home/modules/cli/fastfetch.nix
  no_match -F -q '{#39}' home/modules/cli/fastfetch.nix
  rg -q 'ZLE_RPROMPT_INDENT = "0"' home/modules/terminal/zsh.nix
  rg -q -e "-builtin:tool-search" home/modules/programs/pi-coding-agent.nix
  no_match -q -e "-builtin:mcp" home/modules/programs/pi-coding-agent.nix
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
  rg -q -U 'theme = \{\s*name = "wallust"' home/modules/programs/opencode.nix
  rg -q '.codex/themes/wallust.tmTheme' home/modules/programs/codex.nix
  no_match -q '.config/codex/themes' home/modules/programs/codex.nix
  rg -q 'template = "claude-code.json"' home/modules/programs/claude-code.nix
  rg -q 'theme = "custom:wallust"' home/modules/programs/claude-code.nix
  test -f assets/wallust-templates/claude-code.json
  rg -q -F '"claude": "{{color12}}"' assets/wallust-templates/claude-code.json
  rg -q -F '"text": "#e0e0e0"' assets/wallust-templates/claude-code.json
  rg -q -F '"userMessageBackground": "#1a1a1a"' assets/wallust-templates/claude-code.json
  rg -q 'template = "opencode.json"' home/modules/programs/opencode.nix
  test -f assets/wallust-templates/opencode.json
  rg -q -F '"syntaxKeyword": "{{color4}}"' assets/wallust-templates/opencode.json
  rg -q -F '"text": "#e0e0e0"' assets/wallust-templates/opencode.json
  rg -q -F '"border": "#2e2e2e"' assets/wallust-templates/opencode.json
  test -f assets/wallust-templates/fzf
  rg -q -F -- '--color=fg:#e0e0e0' assets/wallust-templates/fzf
  no_match -q '\{\{\s*color(7|8)\b' assets/wallust-templates
  for template in bat.tmTheme btop.theme claude-code.json crush.json delta.gitconfig flavor.toml fzf ghostty lazygit.yml nvim-colors.lua opencode.json sequences; do
    test -f "assets/wallust-templates/$template"
  done
  rg -q 'template = "bat.tmTheme"' home/modules
  rg -q 'template = "btop.theme"' home/modules
  rg -q 'template = "claude-code.json"' home/modules
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
  rg -q 'aiRender\.wrapWithOpenCodeKey "crush"' home/modules/programs/crush.nix
  rg -q 'providers\."opencode-go"\.api_key = "\$OPENCODE_API_KEY"' home/modules/programs/crush.nix
  rg -q 'aiRender\.wrapWithOpenCodeKey "opencode"' home/modules/programs/opencode.nix
  rg -q -F 'wrapWithOpenCodeKey "pi" pkgs.pi-coding-agent ["opencode-go"]' home/modules/programs/pi-coding-agent.nix
  no_match -q 'hideThinkingBlock' home/modules/programs/pi-coding-agent.nix
  no_match -q 'auth\.json' home/modules/programs/pi-coding-agent.nix
  no_match -q '_load_ai_keys|_ensure_ai_keys_preexec|load-ai-keys' home/modules/terminal/zsh.nix
  no_match -q '\.artifacts/context\.md' home/modules/ai/rules.nix
  no_match -q 'ste100 =' home/modules/ai/disciplines.nix
  rg -q 'Zero prose, greetings, or recaps' home/modules/ai/disciplines.nix
  rg -q 'objdump' home/modules/ai/disciplines.nix
  rg -q 'Omit a line that has no content' home/modules/ai/disciplines.nix
  rg -q 'dropDisciplines = \["search"\];' home/modules/programs/claude-code.nix
  ! test -e skills/configure-nixos
  test -f .agents/skills/configure-nixos/SKILL.md
  test -L .claude/skills/configure-nixos
  rg -q 'disable-model-invocation: true' skills/ship-changes/SKILL.md
  rg -q 'compaction =' home/modules/ai/options.nix
  rg -q 'CLAUDE_CODE_AUTO_COMPACT_WINDOW' home/modules/programs/claude-code.nix
  rg -q 'model_auto_compact_token_limit' home/modules/programs/codex.nix
  rg -q 'reserveTokens' home/modules/programs/pi-coding-agent.nix
  rg -q 'compaction = \{' home/modules/programs/opencode.nix
  rg -q 'curve =' home/modules/programs/hyprland/hyprland.nix
  rg -q 'appleDecel' home/modules/programs/hyprland/hyprland.nix
  rg -q 'appleSpring' home/modules/programs/hyprland/hyprland.nix
  rg -q 'new_render_scheduling = true;' home/modules/programs/hyprland/hyprland.nix
  rg -q 'direct_scanout = 2;' home/modules/programs/hyprland/hyprland.nix
  rg -q 'mouse_refocus = false;' home/modules/programs/hyprland/hyprland.nix
  rg -q 'samples = 2;' home/modules/programs/hyprland/hyprland.nix
  no_match -q 'style = "(fade|slidefadevert)' home/modules/programs/hyprland/hyprland.nix
  rg -q 'style = "slidevert";' home/modules/programs/hyprland/hyprland.nix
  rg -q 'stiffness = 460;' home/modules/programs/hyprland/hyprland.nix
  rg -q 'render_power = 4;' home/modules/programs/hyprland/hyprland.nix
  rg -q 'bevel_strength =' home/modules/programs/hyprland/hyprland.nix
  rg -q 'blur_strength = 0\.65' home/modules/programs/hyprland/hyprland.nix
  rg -q 'lens_distortion = 0\.34' home/modules/programs/hyprland/hyprland.nix
  rg -q 'active_opacity = 0\.80;' home/modules/programs/hyprland/hyprland.nix
  rg -q 'inactive_opacity = 0\.66;' home/modules/programs/hyprland/hyprland.nix
  no_match -q 'if hl\.plugin\.[a-z]+(\.layer)? (then|and)' home/modules/programs/hyprland/hyprland.nix
  no_match -q 'if hl\.plugin\.[a-z]+(\.layer)? (then|and)' home/modules/programs/hyprland/keybinds.nix
  rg -q 'modal = mkOption' home/modules/environment/rules.nix
  rg -q 'browser\.link\.open_newwindow\.restriction' home/modules/programs/gui/zen-browser.nix
  rg -q 'zen-extension-popups' home/modules/programs/gui/zen-browser.nix
  rg -q 'zen-modals' home/modules/programs/gui/zen-browser.nix
  rg -q 'ignoreAlpha = 0\.15;' home/modules/programs/noctalia.nix
  rg -q 'pure_black_dark = true;' home/modules/programs/noctalia.nix
  rg -q 'wallpaper_scheme = "faithful";' home/modules/programs/noctalia.nix
  rg -q 'control_center\.width = 700;' home/modules/programs/noctalia.nix
  rg -q 'panel_overlap = 3;' home/modules/programs/noctalia.nix
  rg -q 'margin_ends = 826;' home/modules/programs/noctalia.nix
  rg -q 'corner_radius_scale = 0\.95;' home/modules/programs/noctalia.nix
  rg -q 'button_borders = false;' home/modules/programs/noctalia.nix
  rg -q 'card_borders = false;' home/modules/programs/noctalia.nix
  rg -q 'shadow\.alpha = 0\.25;' home/modules/programs/noctalia.nix
  rg -q 'margin_edge = 0;' home/modules/programs/noctalia.nix
  rg -q 'concave_edge_corners = true;' home/modules/programs/noctalia.nix
  no_match -q 'radius_top_(left|right) = 0;' home/modules/programs/noctalia.nix
  rg -q 'border_width = 0;' home/modules/programs/noctalia.nix
  rg -q 'capsule_border_width = 0;' home/modules/programs/noctalia.nix
  rg -q 'borders = false;' home/modules/programs/noctalia.nix
  rg -q 'background_opacity = 0\.55;' home/modules/programs/noctalia.nix
  rg -q 'capsule_opacity = 0\.22;' home/modules/programs/noctalia.nix
  rg -q 'control_center_placement = "attached";' home/modules/programs/noctalia.nix
  rg -q 'bagusk99/super-caffeine:super-caffeine-toggle' home/modules/programs/noctalia.nix
  rg -q -U 'nightlight = \{\n\s+enabled = false;' home/modules/programs/noctalia.nix
  rg -q 'control_center_position = "top_center";' home/modules/programs/noctalia.nix
  rg -q 'noctalia-clean' home/modules/programs/hyprland/hyprland.nix
  rg -q 'mask_threshold = 0\.55' home/modules/programs/hyprland/hyprland.nix
  rg -q 'layers = \{enabled = true;\}' home/modules/programs/hyprland/hyprland.nix
  rg -q '"plugin\.hyprglass\.layer"' home/modules/programs/hyprland/hyprland.nix
  rg -q 'claudeLsp =' home/modules/core/toolchain.nix
  rg -q 'lspServers = config\.toolchain\.claudeLsp;' home/modules/programs/claude-code.nix
  rg -q 'default = 20;' home/modules/environment/compositor.nix
  rg -q 'gtk-menu-images = false;' home/modules/programs/gtk/theme.nix
  rg -q 'mactahoe-gtk-accent' home/modules/programs/gtk/dconf.nix
  test -f pkgs/mactahoe-golden-gate.css
  no_match -q 'border-radius' pkgs/mactahoe-golden-gate.css
  no_match -q 'margin:' pkgs/mactahoe-golden-gate.css
  no_match -q '@theme_(base|bg|unfocused)' pkgs/mactahoe-golden-gate.css
  rg -q '\.sidebar-pane \.navigation-sidebar' pkgs/mactahoe-golden-gate.css
  rg -q 'dialog\.alert \.response-area' pkgs/mactahoe-golden-gate.css
  rg -q 'mactahoe-golden-gate\.css' pkgs/mactahoe-gtk-theme.nix
  rg -q 'wm_radius: 20px' pkgs/mactahoe-gtk-theme.nix
  rg -q 'trans_opacity: 0\.84;' pkgs/mactahoe-gtk-theme.nix
  rg -q 'secondary_opacity: 0\.68;' pkgs/mactahoe-gtk-theme.nix
  rg -q 'percentage\(\$trans_opacity\)' pkgs/mactahoe-gtk-theme.nix
  rg -q 'backdrop_color: \$window_bg' pkgs/mactahoe-gtk-theme.nix
  rg -q 'background-color: \$window_bg;/' pkgs/mactahoe-gtk-theme.nix
  rg -q 'mn_radius: 20px' pkgs/mactahoe-gtk-theme.nix
  rg -q 'gtkalpha\(\$base_color, \$trans_opacity\)' pkgs/mactahoe-gtk-theme.nix
  rg -q 'setupOpts.file_types = \[ "markdown" \];' home/modules/core/toolchain.nix
  rg -q 'goldenGateCss' pkgs/mactahoe-gtk-accent.nix
  rg -q '\{\s*"r",\s*mode\s*=' home/modules/programs/nvim/keymaps.nix
  rg -q '\{\s*"s",\s*mode\s*=' home/modules/programs/nvim/keymaps.nix
  rg -q 'key = "rW"' home/modules/programs/nvim/keymaps.nix
  rg -q 'key = "rQ"' home/modules/programs/nvim/keymaps.nix
  rg -q '\{ "sa", desc = "Add surrounding" \}' home/modules/programs/nvim/keymaps.nix
  no_match -q '"gege"' home/modules/programs/nvim/keymaps.nix

  touch $out
''
