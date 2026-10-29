{ config, pkgs, lib, ... }:

let
  pills = config.styles.pills.tmux;

  colors = [
    "cyan"
    "blue"
    "magenta"
    "green"
    "yellow"
    "red"
  ];

  mkColorCycle =
    cols:
    let
      len = builtins.length cols;
      buildCond =
        i:
        if i == len - 1 then
          builtins.elemAt cols i
        else
          "#{?#{==:#{e|%:#{window_index},${toString len}},${toString (i + 1)}},${builtins.elemAt cols i},${buildCond (i + 1)}}";
    in
    buildCond 0;

  windowColor = mkColorCycle colors;
  windowIcons = "#{?window_active, 󰖯,}#{?window_last_flag, 󰁍,}#{?window_bell_flag, 󰂞,}#{?window_activity_flag, 󱅫,}#{?window_silence_flag, 󰂛,}#{?window_zoomed_flag, 󰁌,}#{?window_marked_flag, 󰃀,}#{?pane_synchronized, 󰓦,}";
  modeText = "#{?client_prefix,PREFIX,#{?pane_in_mode,COPY,NORMAL}}";
  modeColor = "#{?client_prefix,yellow,#{?pane_in_mode,magenta,blue}}";

  batteryBin = "${pkgs.tmux-battery}/bin/tmux-battery";
  continuumSave = "${pkgs.tmuxPlugins.continuum}/share/tmux-plugins/continuum/scripts/continuum_save.sh";
in
{
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    terminal = "tmux-256color";
    baseIndex = 1;
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = smart-splits;
        extraConfig = ''
          set -g @smart-splits_no_wrap \'\' # to disable wrapping. (any value disables wrapping)

          set -g @smart-splits_move_left_key  'C-h' # key-mapping for navigation with Alt
          set -g @smart-splits_move_down_key  'C-j' #  --"--
          set -g @smart-splits_move_up_key    'C-k' #  --"--
          set -g @smart-splits_move_right_key 'C-l' #  --"--

          set -g @smart-splits_resize_left_key  'M-h' # key-mapping for resizing with Ctrl
          set -g @smart-splits_resize_down_key  'M-j' #  --"--
          set -g @smart-splits_resize_up_key    'M-k' #  --"--
          set -g @smart-splits_resize_right_key 'M-l' #  --"--

          set -g @smart-splits_resize_step_size '5' # change the step-size for resizing.
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];
    extraConfig = ''
      set -g pane-base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on

      set -s extended-keys on
      set -s extended-keys-format csi-u
      set -as terminal-features ",*:RGB,*:extkeys"
      set -ga terminal-overrides ",*:Tc"

      set -g set-clipboard on
      set -g allow-passthrough on
      set -g status-interval 1

      # Prefix + C-<key> passes the control key to the active pane.
      # Do not bind these to tmux actions; that makes the keys unreachable
      # inside shells, editors, and other full-screen programs.
      bind C-Space send-prefix
      bind C-b send-keys C-b
      bind C-g send-keys C-g
      bind C-h send-keys C-h
      bind C-j send-keys C-j
      bind C-k send-keys C-k
      bind C-l send-keys C-l
      bind C-n send-keys C-n
      bind C-p send-keys C-p
      bind C-t send-keys C-t
      bind C-y send-keys C-y
      bind l send-keys l

      # Remove old prefix popup bindings left by earlier configs.
      unbind -q g
      unbind -q y
      unbind -q b
      unbind -q t

      # Clear legacy root bindings that stole these keys before the prefix
      # pass-through rules existed.
      unbind -n C-1
      unbind -n C-2
      unbind -n C-3
      unbind -n C-4
      unbind -n C-5
      unbind -n C-6
      unbind -n C-7
      unbind -n C-8
      unbind -n C-9

      # Show every prefix binding, not just the few with -N notes.
      bind -N "List all key bindings" ? list-keys -T prefix
      bind / command-prompt -k -p key { list-keys -T prefix "%%" }

      bind x kill-pane
      bind X kill-window
      bind B break-pane

      unbind r
      bind r source-file ~/.config/tmux/tmux.conf

      # Window navigation (p/n; C-p/C-n stay available to the pane)
      bind c new-window -c "#{pane_current_path}"
      bind Tab last-window
      bind -n C-p previous-window
      bind -n C-n next-window
      bind -n C-Tab next-window
      bind -n C-S-Tab previous-window
      bind -n C-BTab previous-window

      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9

      # Splits & Layout equalizers (Shift key symmetry)
      unbind %
      bind \\ split-window -h -c "#{pane_current_path}"

      unbind \"
      bind - split-window -v -c "#{pane_current_path}"

      bind | select-layout even-horizontal
      bind _ select-layout even-vertical
      bind = select-layout tiled

      bind -r M-j resize-pane -D 5
      bind -r M-k resize-pane -U 5
      bind -r M-h resize-pane -L 5
      bind -r M-l resize-pane -R 5

      bind -r m resize-pane -Z

      set -g mode-keys vi
      set -g status-keys vi

      unbind v
      bind v copy-mode
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "wl-copy"
      bind -T copy-mode-vi Escape send -X cancel
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "wl-copy"

      # Direct C-g/C-y/C-b open popups. Prefix C-g/C-y/C-b remain
      # pass-through bindings above.
      bind -n C-g display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "lazygit"
      bind -n C-y display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "yazi"
      bind -n C-b display-popup -d "#{pane_current_path}" -w 90% -h 90% -E "btop"

      # Status bar configuration
      set -g status-position top
      set -g status-justify centre
      set -g status-style "bg=default,fg=brightwhite"

      set -g status-left-length 80
      set -g status-right-length 80
      # Continuum's autosave hook must survive this status-right definition.
      set -g status-right '#(${continuumSave}) ${pills.right { text = "%d %b"; icon = "󰃭"; accent = "blue"; }}  ${pills.right { text = "%H:%M"; icon = "󱑂"; accent = "magenta"; }} '

      # Left status: Mode pill at left-most, followed by Session pill and Battery pill
      set -g status-left ' ${pills.mode { text = modeText; color = modeColor; }}  ${pills.left { icon = ""; text = "#S"; accent = modeColor; boldIcon = true; }}#{?#(${batteryBin} pct),  ${pills.left { icon = "#(${batteryBin} icon)"; text = "#(${batteryBin} pct)%"; accent = "#(${batteryBin} color)"; iconFg = "white"; }},}'

      # Window status: Rotating color pills across all windows; active window distinguished with illuminated body
      set -g window-status-separator "  "
      set -g window-status-activity-style default
      set -g window-status-bell-style default
      set -g window-status-current-style default
      set -g window-status-format '${
        pills.left {
          icon = "#I";
          text = "#W${windowIcons}";
          accent = windowColor;
          charcoal = "#{?#{||:#{window_bell_flag},#{||:#{window_activity_flag},#{window_silence_flag}}},white,brightblack}";
          charcoalFg = "#{?#{||:#{window_bell_flag},#{||:#{window_activity_flag},#{window_silence_flag}}},black,brightwhite}";
        }
      }'

      set -g window-status-current-format '${pills.left { icon = "#I"; text = "#W${windowIcons}"; accent = windowColor; charcoal = "white"; charcoalFg = "black"; boldText = true; boldIcon = true; }}'

      # Pane & floating popup borders
      set -s theme terminal
      set -g pane-border-lines single
      set -g pane-border-indicators both
      set -g pane-border-style "fg=brightblack,bg=default"
      set -g pane-active-border-style "fg=${modeColor},bg=default"
      set -g popup-border-lines rounded
      set -g popup-style "bg=default,fg=default"
      set -g popup-border-style "fg=${modeColor},bg=default"
      set -g menu-border-lines rounded
      set -g menu-style "bg=default,fg=default"
      set -g menu-border-style "fg=${modeColor},bg=default"
      set -g display-panes-border-style "fg=${modeColor},bg=default"
      set -g tree-mode-border-style "fg=${modeColor},bg=default"
    '';
  };

  home.activation.tmuxReload = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${pkgs.tmux}/bin/tmux info >/dev/null 2>&1; then
      ${pkgs.tmux}/bin/tmux source-file ~/.config/tmux/tmux.conf >/dev/null 2>&1 || true
    fi
  '';
}
