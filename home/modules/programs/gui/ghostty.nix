{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      theme = "wallust";
      background-opacity = 1.0;
      notify-on-command-finish = "unfocused";
      font-family = [
        config.styles.fonts.monospace.name
        config.styles.fonts.emoji.name
      ];
      font-size = config.styles.fonts.sizes.terminal;

      # Clipboard & mouse defaults
      copy-on-select = true;
      clipboard-paste-protection = true;
      clipboard-trim-trailing-spaces = true;

      # Clear default keybinds to protect tmux/neovim shortcuts (Alt+1..9, splits),
      # while explicitly re-enabling essential terminal utilities:
      keybind = [
        "clear"
        "ctrl+shift+t=new_tab"
        "ctrl+shift+n=new_window"
        "ctrl+shift+w=close_surface"
        "ctrl+shift+q=close_tab"
        "ctrl+shift+alt+right=new_split:right"
        "ctrl+shift+alt+down=new_split:down"
        "ctrl+alt+left=goto_split:left"
        "ctrl+alt+right=goto_split:right"
        "ctrl+alt+up=goto_split:up"
        "ctrl+alt+down=goto_split:down"
        "ctrl+shift+backquote=toggle_quick_terminal"
        # Clipboard copy & paste
        "ctrl+shift+c=copy_to_clipboard:mixed"
        "ctrl+shift+v=paste_from_clipboard"
        "copy=copy_to_clipboard:mixed"
        "paste=paste_from_clipboard"
        "ctrl+insert=copy_to_clipboard:mixed"
        "shift+insert=paste_from_selection"

        # Font zoom controls
        "ctrl++=increase_font_size:1"
        "ctrl+==increase_font_size:1"
        "ctrl+-=decrease_font_size:1"
        "ctrl+0=reset_font_size"

        # Terminal utilities & search
        "ctrl+shift+,=reload_config"
        "ctrl+shift+p=toggle_command_palette"
        "ctrl+shift+f=start_search"
        "ctrl+shift+i=inspector:toggle"

        # Scrollback
        "shift+page_up=scroll_page_up"
        "shift+page_down=scroll_page_down"
        "shift+home=scroll_to_top"
        "shift+end=scroll_to_bottom"
      ];
    };
  };

  home.activation.ghosttyReload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.ghostty-reload}/bin/ghostty-reload || true
  '';

  programs.wallust.settings = {
    templates.ghostty = {
      template = "ghostty";
      target = "${config.xdg.configHome}/ghostty/themes/wallust";
    };
    hooks.ghostty = "${pkgs.ghostty-reload}/bin/ghostty-reload";
  };
}

