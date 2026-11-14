{
  config,
  lib,
  pkgs,
  ...
}:
let
  treeAliases = builtins.listToAttrs (
    map (depth: {
      name = "l${toString (lib.mod depth 10)}";
      value = "l -TL ${toString depth}";
    }) (lib.range 1 10)
  );
in
{
  # ---------------------------------------------------------------------------
  # Shell Aliases & Pager
  # ---------------------------------------------------------------------------
  home.sessionVariables.PAGER = "less -FRX";

  home.shellAliases =
    {
      # Privilege & navigation
      "_" = "sudo ";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      bd = ''cd "$OLDPWD"'';

      # File operations & safety
      cp = "cp -iv";
      mv = "mv -iv";
      md = "mkdir -pv";
      rmd = "rm -rf";
      rmt = "rip";
      urm = "rip -u";

      # Directory listing (l1..l0 generated via treeAliases)
      l = "eza --icons=auto --short-nix -olahH";
      lt = "l -TL 2";

      # Core CLI tools
      nv = "nvim";
      g = "git";
      ld = "lazydocker";
      cat = "bat";
      diff = "delta";
      man = "batman";

      # Systemd & Nix lifecycle
      sc = "_ systemctl";
      scu = "systemctl --user";
      nixos-rb = "_ nixos-rebuild switch --flake .";
      nix-gc = "_ nix store gc";
      hm = "home-manager";
      hm-rb = "hm switch --flake . -b backup";
      hm-gc = ''hm expire-generations "-3 days"'';
    }
    // treeAliases;

  # ---------------------------------------------------------------------------
  # Zsh Configuration
  # ---------------------------------------------------------------------------
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    defaultKeymap = "viins";
    autocd = true;

    # Only non-default Home Manager history settings are declared here.
    # (append, share, ignoreSpace, ignoreDups, size=10000, save=10000 are HM defaults)
    history = {
      extended = true;
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
    };

    sessionVariables = {
      LS_COLORS = "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arc=01;31:*.arj=01;31:*.taz=01;31:*.lha=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.tlz=01;31:*.txz=01;31:*.tzo=01;31:*.t7z=01;31:*.zip=01;31:*.z=01;31:*.dz=01;31:*.gz=01;31:*.lrz=01;31:*.lz=01;31:*.lzo=01;31:*.xz=01;31:*.zst=01;31:*.tzst=01;31:*.bz2=01;31:*.bz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tz=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.war=01;31:*.ear=01;31:*.sar=01;31:*.rar=01;31:*.alz=01;31:*.ace=01;31:*.zoo=01;31:*.cpio=01;31:*.7z=01;31:*.rz=01;31:*.cab=01;31:*.wim=01;31:*.swm=01;31:*.dwm=01;31:*.esd=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.png=01;35:*.svg=01;35:*.webp=01;35:*.mp4=01;35:*.mkv=01;35:*.webm=01;35:*.mov=01;35:*.flac=00;36:*.mp3=00;36:*.ogg=00;36:*.opus=00;36:*.wav=00;36:*.pdf=00;33:*.md=01;33:*.nix=01;34";
      ZLE_RPROMPT_INDENT = "0";
      ZVM_INIT_MODE = "sourcing";
      ZVM_VI_HIGHLIGHT_BACKGROUND = "8";
      ZVM_VI_HIGHLIGHT_FOREGROUND = "15";
      ZVM_VI_HIGHLIGHT_EXTRASTYLE = "bold";
      LESSOPEN = "|${pkgs.bat-extras.batpipe}/bin/batpipe %s";
      LESS = "-FRX";
    };

    fastSyntaxHighlighting.enable = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=8";
    };

    shellGlobalAliases = {
      NE = "2> /dev/null";
      DN = "> /dev/null";
      NUL = "> /dev/null 2>&1";
      JQ = "| jq";
      F = "| fzf";
      L = "| $PAGER";
      D = "| delta";
      C = "| bat";
      H = "| head";
      T = "| tail";
      G = "| rg";
    };

    # zsh-vi-mode loads synchronously before fzf-tab so Tab completion bindings survive.
    plugins = with pkgs; [
      {
        name = "zsh-vi-mode";
        src = zsh-vi-mode;
        file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
      }
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
    ];

    # Ensure standalone Home Manager's profile completions are in fpath before compinit.
    # Rebuild completion dump when stale (>20h) or after any home-manager switch.
    completionInit = ''
      for hm_dir in \
        "${config.xdg.stateHome}/nix/profiles/home-manager/home-path/share/zsh/site-functions" \
        "${config.xdg.stateHome}/nix/profiles/home-manager/home-path/share/zsh/vendor-completions"; do
        [[ -d "$hm_dir" ]] && fpath=("$hm_dir" $fpath)
      done
      unset hm_dir

      autoload -Uz compinit
      zmodload zsh/stat
      mkdir -p "$XDG_CACHE_HOME/zsh"
      local zcd="$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
      local hm_prof="${config.xdg.stateHome}/nix/profiles/home-manager"
      local zcd_mtime=0 hm_mtime=0
      [[ -f "$zcd" ]] && zcd_mtime="$(zstat +mtime "$zcd")"
      [[ -L "$hm_prof" || -e "$hm_prof" ]] && hm_mtime="$(zstat -L +mtime "$hm_prof")"
      if (( zcd_mtime > hm_mtime && EPOCHSECONDS - zcd_mtime < 72000 )); then
        compinit -C -d "$zcd"
      else
        compinit -d "$zcd"
        { zcompile "$zcd" } &!
      fi
      (( ''${+functions[_man]} )) && compdef _man batman
      (( ''${+functions[_rg]} )) && compdef _rg batgrep
    '';

    initContent = ''
      # -----------------------------------------------------------------------
      # 1. Shell Options (non-default options only)
      # -----------------------------------------------------------------------
      # Navigation & directory stack
      setopt AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT CDABLE_VARS

      # Globbing & completion behavior
      setopt EXTENDED_GLOB GLOB_DOTS NUMERIC_GLOB_SORT
      setopt COMPLETE_IN_WORD ALWAYS_TO_END PATH_DIRS
      unsetopt CASE_GLOB

      # History & interactive ergonomics
      setopt HIST_REDUCE_BLANKS HIST_NO_STORE HIST_VERIFY HIST_FCNTL_LOCK
      setopt INTERACTIVE_COMMENTS LONG_LIST_JOBS NOTIFY
      unsetopt FLOWCONTROL BEEP

      # -----------------------------------------------------------------------
      # 2. Completion System (zstyle & fzf-tab)
      # -----------------------------------------------------------------------
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*' verbose yes
      zstyle ':completion:*' completer _complete _ignored _match
      zstyle ':completion:*' menu no
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' list-prompt '%S%M matches%s'

      # Completion cache
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path "${config.xdg.cacheHome}/zsh/.zcompcache"

      # Group & diagnostic formatting
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*:options' auto-description '%d'
      zstyle ':completion:*:corrections' format '[%d errors: %e]'
      zstyle ':completion:*:warnings' format 'no matches'

      # Context-specific completion rules
      zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
      zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
      zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
      zstyle ':completion:*:git-checkout:*' sort false
      zstyle ':completion:*:git-checkout:*' ignore-line yes
      zstyle ':completion:*:git-*' verbose yes
      zstyle ':completion:*:(rm|rip|kill|diff):*' ignore-line other
      zstyle ':completion:*:rm:*' file-patterns '*:all-files'
      zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,command -w'
      zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
      zstyle ':completion:*:*:kill:*' force-list always
      zstyle ':completion:*:*:kill:*' insert-ids single
      zstyle ':completion:*:manuals' separate-sections true
      zstyle ':completion:*:manuals.(^1*)' insert-sections true

      # fzf-tab popup, Base16 colors, and contextual previews
      zstyle ':fzf-tab:*' use-fzf-default-opts yes
      zstyle ':fzf-tab:*' group-colors \
        $'\033[34m' $'\033[32m' $'\033[33m' $'\033[35m' $'\033[36m' $'\033[31m'
      zstyle ':fzf-tab:*' fzf-command 'fzf-tmux -p 75%,40% --'
      zstyle ':fzf-tab:*' fzf-flags \
        --layout=reverse \
        --border=rounded \
        --border-label=" Completions " \
        --border-label-pos=0 \
        --preview-window='right:60%,border-rounded' \
        --prompt="❯ " \
        --marker="❯" \
        --pointer="❯"
      zstyle ':fzf-tab:complete:cd:*' fzf-preview '${pkgs.eza}/bin/eza --tree --level=2 --color=always --icons=auto $realpath'
      zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
      zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps -p $word -o pid,ppid,user,%cpu,%mem,etime,cmd -w'

      # -----------------------------------------------------------------------
      # 3. Line Editor (ZLE) & Vi Keybindings
      # -----------------------------------------------------------------------
      # Path-aware word deletion (Ctrl-W stops at slashes)
      autoload -Uz select-word-style edit-command-line
      select-word-style bash
      zle -N edit-command-line

      # Insert mode: standard readline editing & cursor movement
      bindkey -M viins '^U' backward-kill-line
      bindkey -M viins '^W' backward-kill-word
      bindkey -M viins '^A' vi-beginning-of-line
      bindkey -M viins '^E' vi-end-of-line
      bindkey -M viins '^T' transpose-chars
      bindkey -M viins '^[[1;5D' vi-backward-word
      bindkey -M viins '^[[1;5C' vi-forward-word
      bindkey -M viins '^[[1;6D' vi-backward-word
      bindkey -M viins '^[[1;6C' vi-forward-word
      bindkey -M viins '^[[1~' vi-beginning-of-line
      bindkey -M viins '^[[4~' vi-end-of-line
      bindkey -M viins '^[OB' down-line-or-history
      bindkey -M viins '^[[B' down-line-or-history
      bindkey -M viins '^[?' run-help

      # Insert & Normal mode: fzf history, file, and directory pickers
      for km in viins vicmd; do
        bindkey -M "$km" '^R' fzf-history-widget
        bindkey -M "$km" '^F' fzf-file-widget
        bindkey -M "$km" '^O' fzf-cd-widget
      done
      bindkey -M viins '^[[A' fzf-history-widget
      bindkey -M viins '^[OA' fzf-history-widget
      bindkey -M vicmd 'v' edit-command-line

      # Unbind conflicting or noisy default bindings (keeps C-d/C-n/C-p free for tmux)
      for key in '^D' '^K' '^N' '^P' '^Q' '^X~' '^[,' '^[/' '^[~' '\ec'; do
        bindkey -M viins -r "$key"
      done
      for key in '^N' '^P' '^Q' '^T' '\ec'; do
        bindkey -M vicmd -r "$key"
      done
      bindkey -M viins -r -R '\M-^@'-'\M-^?'

      # -----------------------------------------------------------------------
      # 4. Terminal Integration (Wallust, Window Title, Login Fastfetch)
      # -----------------------------------------------------------------------
      if [[ -t 1 && -f "''${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences" ]]; then
        command tr -d '\r\n' < "''${XDG_CACHE_HOME:-$HOME/.cache}/wallust/sequences"
      fi

      if [[ -o login && -z "$TMUX" ]] && (( ''${+commands[fastfetch]} )); then
        fastfetch
      fi

      set_win_title() { print -Pn "\e]2;%~\a" }
      precmd_functions+=(set_win_title)

      # -----------------------------------------------------------------------
      # 5. On-Demand Vaultwarden AI Keys (rbw)
      # -----------------------------------------------------------------------
      _load_ai_keys() {
        if (( ''${+commands[rbw]} )) && rbw unlocked >/dev/null 2>&1; then
          local key exa_key
          key="$(rbw get --folder dev/keys opencode 2>/dev/null || true)"
          if [[ -n "$key" ]]; then
            export OPENCODE_API_KEY="$key"
            export OPENCODE_GO_API_KEY="$key"
          fi
          exa_key="$(rbw get --folder dev/keys exa 2>/dev/null || rbw get exa 2>/dev/null || true)"
          if [[ -n "$exa_key" ]]; then
            export EXA_API_KEY="$exa_key"
          fi
        fi
      }

      _ensure_ai_keys_preexec() {
        if [[ -z "$OPENCODE_API_KEY" || -z "$EXA_API_KEY" ]]; then
          case "$1" in
            opencode*|pi*|crush*|kiro*|codex*|agy*|antigravity*|hermes*|copilot*)
              _load_ai_keys
              ;;
          esac
        fi
      }
      autoload -Uz add-zsh-hook
      add-zsh-hook preexec _ensure_ai_keys_preexec

      load-ai-keys() {
        if ! rbw unlocked >/dev/null 2>&1; then
          rbw unlock || return 1
        fi
        _load_ai_keys
        local loaded=()
        [[ -n "$OPENCODE_API_KEY" ]] && loaded+=("OPENCODE_API_KEY")
        [[ -n "$EXA_API_KEY" ]] && loaded+=("EXA_API_KEY")
        if (( ''${#loaded[@]} > 0 )); then
          echo "AI keys loaded into environment: ''${(j:, :)loaded}."
        else
          echo "Warning: No keys retrieved from rbw (check folder dev/keys)." >&2
        fi
      }
    '';
  };
}
