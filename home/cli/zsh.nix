{ config, pkgs, ... }:
{
  home.shellAliases = {
    "_" = "sudo ";
    "..." = "cd ../..";
    "...." = "cd ../../..";
    bd = ''cd "$OLDPWD"'';
    cp = "cp -iv";
    mv = "mv -iv";
    md = "mkdir -pv";
    rmd = "rm -rf";

    l = "eza --icons=auto --short-nix -olahH";

    # tree view
    l1 = "l -TL 1";
    l2 = "l -TL 2";
    l3 = "l -TL 3";
    l4 = "l -TL 4";
    l5 = "l -TL 5";
    l6 = "l -TL 6";
    l7 = "l -TL 7";
    l8 = "l -TL 8";
    l9 = "l -TL 9";
    l0 = "l -TL 10";

    nv = "nvim";
    g = "git";
    cat = "bat";
    diff = "batdiff";
    man = "batman";
    sc = "_ systemctl";
    scu = "systemctl --user";

    nixos-rb = "_ nixos-rebuild switch --flake .";
    nix-gc = "_ nix store gc";

    hm = "home-manager";
    hm-rb = "hm switch --flake . -b backup";
    hm-rb-legacy = "hm switch";
    hm-gc = ''hm expire-generations "-3 days"'';
  };

  programs.zsh = {
    dotDir = "${config.xdg.configHome}/zsh/";
    enable = true;
    enableCompletion = true;
    defaultKeymap = "viins";
    autocd = true;

    history = {
      append = true;
      share = true;
      ignoreSpace = true;
      ignoreDups = true;
      ignoreAllDups = true;
      saveNoDups = true;
      findNoDups = true;
      expireDuplicatesFirst = true;
      ignorePatterns = [
        "exit"
        "clear"
        "history*"
        "l"
        "ls"
        "pwd"
      ];
      save = 10000;
      size = 10000;
    };

    fastSyntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    shellGlobalAliases = {
      NE = "2> /dev/null";
      DN = "> /dev/null";
      NUL = "> /dev/null 2>&1";
      JQ = "| jq";
      F = "| $FUZZY"; # TODO install fzf
      L = "| $PAGER";
      D = "| delta"; # TODO install delta
      C = "| bat";
      H = "| head";
      T = "| tail";
      G = "| rg";
    };

    plugins = with pkgs; [
      {
        name = "fzf-tab";
        src = zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "you-should-use";
        src = zsh-you-should-use;
        file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
      }
      {
        name = "zsh-vi-mode";
        src = zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
    ];

    completionInit = ''
      autoload -U compinit
      compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION" -C
      (zcompile "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION" >/dev/null 2>&1 &)
    '';

    initContent = ''
      unsetopt MENU_COMPLETE
      unsetopt FLOWCONTROL
      unsetopt CASE_GLOB
      setopt AUTO_MENU
      setopt AUTO_LIST
      setopt AUTO_PARAM_SLASH
      setopt EXTENDED_GLOB
      setopt PATH_DIRS
      setopt COMPLETE_IN_WORD
      setopt ALWAYS_TO_END
      setopt HIST_REDUCE_BLANKS
      setopt HIST_NO_STORE
      setopt HIST_VERIFY

      # Common settings
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*' completer _complete _match _history
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS} # Enable list colors
      zstyle ':completion:*' list-prompt '%S%M matches %s'

      # Cache
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/.zcompcache"

      # Completion formatting
      zstyle ':completion:*' format '[%d]'
      zstyle ':completion:*:options' auto-description '%d'
      zstyle ':completion:*:corrections' format '[%d errors: %e]'
      zstyle ':completion:*:warnings' format 'no matches'

      # Hide internal functions
      zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

      # Array index completion
      zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

      # Prioritize directories over users
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'

      # Disable sorting and ignore current branch for checkout
      zstyle ':completion:*:git-checkout:*' sort false
      zstyle ':completion:*:git-checkout:*' ignore-line yes
      zstyle ':completion:*:git-*' verbose yes

      # Don't autocomplete what's already inputed
      zstyle ':completion:*:(rm|kill|diff):*' ignore-line other

      # Show all files fro rm
      zstyle ':completion:*:rm:*' file-patterns '*:all-files'

      # Show my processes, color PIDs, and insert PID number
      zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,command -w'
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
      zstyle ':completion:*:*:kill:*' force-list always
      zstyle ':completion:*:*:kill:*' insert-ids single
            
      # Separate sections and auto insert numbers
      zstyle ':completion:*:manuals' separate-sections true
      zstyle ':completion:*:manuals.(^1*)' insert-sections true

      export FZF_TMUX=1
      export FZF_TMUX_OPTS="-p 75%,65%"
      export FZF_DEFAULT_OPTS="--tmux=center,75%,65% --layout=reverse --border=rounded --prompt='❯ ' --marker='❯' --pointer='❯'"
      export FZF_CTRL_R_OPTS="--border-label=' History ' --border-label-pos=0 --prompt=' History ❯ '"
      export FZF_CTRL_T_OPTS="--border-label=' Files ' --border-label-pos=0 --prompt=' Files ❯ '"
      export FZF_ALT_C_OPTS="--border-label=' Directories ' --border-label-pos=0 --prompt=' Directories ❯ '"

      zstyle ':fzf-tab:*' fzf-flags \
        --tmux=center,75%,65% \
        --height=40% \
        --layout=reverse \
        --border=rounded \
        --border-label=" Completions " \
        --border-label-pos=0 \
        --preview-window='right:60%,border-rounded' \
        --prompt="❯ " \
        --marker="❯" \
        --pointer="❯"

      # Path-aware word deletion (C-w stops at slashes)
      autoload -U select-word-style
      select-word-style bash

      # Pure viins keybindings hook (ensures zsh-vi-mode preserves bindings)
      function zvm_after_init() {
        zvm_bindkey viins '^U' backward-kill-line
        zvm_bindkey viins '^W' backward-kill-word
        zvm_bindkey viins '^A' vi-beginning-of-line
        zvm_bindkey viins '^E' vi-end-of-line
        zvm_bindkey viins '^R' fzf-history-widget
        zvm_bindkey viins '^F' fzf-file-widget
        zvm_bindkey viins '^O' fzf-cd-widget
        zvm_bindkey viins '^[[A' fzf-history-widget
        zvm_bindkey viins '^[OA' fzf-history-widget
        zvm_bindkey vicmd '^R' fzf-history-widget
        zvm_bindkey vicmd '^F' fzf-file-widget
        zvm_bindkey vicmd '^O' fzf-cd-widget
        zvm_bindkey vicmd 'k' up-line-or-history
        zvm_bindkey vicmd 'j' down-line-or-history
        bindkey -M viins '^[?' run-help
        bindkey -M viins -r '^D'
        bindkey -M viins -r '^K'
        bindkey -M viins -r '^N'
        bindkey -M viins -r '^P'
        bindkey -M viins -r '^Q'
        bindkey -M viins -r '^X~'
        bindkey -M viins -r '^[,'
        bindkey -M viins -r '^[/'
        bindkey -M viins -r '^[~'
        bindkey -M viins -r -R '\M-^@'-'\M-^?'
        bindkey -M vicmd -r '^N'
        bindkey -M vicmd -r '^P'
        bindkey -M vicmd -r '^Q'
      }

      bindkey -M viins '^U' backward-kill-line
      bindkey -M viins '^W' backward-kill-word
      bindkey -M viins '^A' vi-beginning-of-line
      bindkey -M viins '^E' vi-end-of-line
      bindkey -M viins '^R' fzf-history-widget
      bindkey -M viins '^F' fzf-file-widget
      bindkey -M viins '^O' fzf-cd-widget
      bindkey -M viins '^[[A' fzf-history-widget
      bindkey -M viins '^[OA' fzf-history-widget

      bindkey "^[OB" down-line-or-history
      bindkey "^[[B" down-line-or-history
      bindkey "^[[1;5D" vi-backward-word
      bindkey "^[[1;5C" vi-forward-word
      bindkey "^[[1;6D" vi-backward-word
      bindkey "^[[1;6C" vi-forward-word
      bindkey "^[[1~" vi-beginning-of-line
      bindkey "^[[4~" vi-end-of-line
      bindkey "^[?" run-help

      # Unbind ^D (list-choices), ^K, ^N, ^P, ^Q, bash/history-complete, and high-bit meta self-insert
      bindkey -M viins -r "^D"
      bindkey -M viins -r "^K"
      bindkey -M viins -r "^N"
      bindkey -M viins -r "^P"
      bindkey -M viins -r "^Q"
      bindkey -M viins -r "^X~"
      bindkey -M viins -r "^[,"
      bindkey -M viins -r "^[/"
      bindkey -M viins -r "^[~"
      bindkey -M viins -r -R "\M-^@"-"\M-^?"
      bindkey -M vicmd -r "^N"
      bindkey -M vicmd -r "^P"
      bindkey -M vicmd -r "^Q"

      # Normal mode history navigation (clean up/down without popup takeovers)
      bindkey -M vicmd 'k' up-line-or-history
      bindkey -M vicmd 'j' down-line-or-history
      bindkey -M vicmd '^R' fzf-history-widget
      bindkey -M vicmd '^F' fzf-file-widget
      bindkey -M vicmd '^O' fzf-cd-widget

      # Source wallust terminal sequences
      if [[ -t 1 && -f "$HOME/.cache/wallust/sequences" ]]; then
        command tr -d '\r\n' < "$HOME/.cache/wallust/sequences"
      fi

      # AI provider API keys from Vaultwarden (rbw folder keys/api). Only when the
      # vault is already unlocked, so a new shell never triggers a pinentry prompt;
      # crush, pi and opencode read these provider keys from the environment.
      if (( ''${+commands[rbw]} )) && rbw unlocked >/dev/null 2>&1; then
        for _rbw_key in OPENCODE_API_KEY:opencode ANTHROPIC_API_KEY:claude GEMINI_API_KEY:gemini; do
          _rbw_val="$(rbw get --folder keys/api "''${_rbw_key##*:}" 2>/dev/null)" \
            && [[ -n "$_rbw_val" ]] \
            && export "''${_rbw_key%%:*}=$_rbw_val"
        done
        [[ -n "$GEMINI_API_KEY" ]] && export GOOGLE_GENERATIVE_AI_API_KEY="$GEMINI_API_KEY"
        unset _rbw_key _rbw_val
      fi

      (( ''${+commands[batpipe]} )) && eval "$(batpipe)"

      # fzf: Ctrl-F files, Ctrl-O directories.
      if (( ''${+widgets[fzf-file-widget]} )); then
        bindkey -M emacs '^F' fzf-file-widget
      fi
      if (( ''${+widgets[fzf-cd-widget]} )); then
        bindkey -M emacs '^O' fzf-cd-widget
      fi

      # Drop fzf's Ctrl-T and Alt-C defaults; restore editing keys.
      bindkey -M emacs '^T' transpose-chars
      bindkey -M viins '^T' transpose-chars
      bindkey -M vicmd '^T' undefined-key
      bindkey -M emacs '\ec' capitalize-word
      bindkey -M viins '\ec' undefined-key
      bindkey -M vicmd '\ec' undefined-key

      (( ''${+commands[fastfetch]} )) && fastfetch
    '';
  };
}
