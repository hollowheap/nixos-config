{ config, lib, ... }:

let
  inherit (lib) hasPrefix hasSuffix mkIf mkOption;
  inherit (lib.types) attrsOf bool str unspecified;

  cfg = config.styles.pills;
  color = import ../../../lib/color.nix { inherit lib; };
  inherit (color) detectContrast;

  ensureTrailingSpace = s: if hasSuffix " " s || hasPrefix "$" s then s else "${s} ";
  ensureLeadingSpace = s: if hasPrefix " " s || hasPrefix "$" s then s else " ${s}";

  mkPiPill = side:
    {
      icon,
      text ? null,
      component ? null,
      accent ? "bright-yellow",
      iconFg ? "black",
      charcoal ? cfg.charcoal,
      charcoalFg ? cfg.charcoalFg,
      bold ? true,
    }:
    let
      body =
        if component != null then
          component
        else
          { type = "text"; text = text; };
    in
    body
    // {
      inherit accent icon iconFg bold;
      iconSide = side;
      bg = charcoal;
      fg = charcoalFg;
      leftCap = cfg.symbols.left;
      rightCap = cfg.symbols.right;
    };
in
{
  options.styles.pills = {
    enable = mkOption {
      type = bool;
      default = true;
      description = "Enable centralized pill style abstraction.";
    };

    symbols = {
      left = mkOption {
        type = str;
        default = "";
        description = "Left pill cap glyph (U+E0B6).";
      };

      right = mkOption {
        type = str;
        default = "";
        description = "Right pill cap glyph (U+E0B4).";
      };
    };

    charcoal = mkOption {
      type = str;
      default = "#2e2e2e";
      description = "Surface background color for pill content body.";
    };

    charcoalFg = mkOption {
      type = str;
      default = "#ffffff";
      description = "Foreground text color for pill content body.";
    };

    detectContrast = mkOption {
      type = unspecified;
      default = detectContrast;
      description = "Contrast detection function: returns black for bright backgrounds, white for dark.";
    };

    # Pure attrset descriptors for mode, icon, content
    descriptors = mkOption {
      type = unspecified;
      default =
        {
          mode =
            { color, text }:
            {
              bg = color;
              fg = detectContrast color;
              cap = color;
              content = text;
            };

          icon =
            { accent, icon }:
            {
              bg = accent;
              fg = detectContrast accent;
              cap = accent;
              icon = icon;
            };

          content =
            { text, bg ? cfg.charcoal, fg ? cfg.charcoalFg }:
            {
              inherit bg fg;
              cap = bg;
              content = text;
            };
        };
      description = "Pure styling attrsets for mode, icon, and content segments.";
    };

    tmux = mkOption {
      type = attrsOf unspecified;
      default = { };
      description = "Tmux pill formatting helpers.";
    };

    lualine = mkOption {
      type = attrsOf unspecified;
      default = { };
      description = "Neovim Lualine pill formatting helpers.";
    };

    incline = mkOption {
      type = attrsOf unspecified;
      default = { };
      description = "Neovim Incline floating pill formatting helpers.";
    };

    starship = mkOption {
      type = attrsOf unspecified;
      default = { };
      description = "Starship prompt pill formatting helpers.";
    };

    pi = mkOption {
      type = attrsOf unspecified;
      default = { };
      description = "Pi statusline JSON pill formatting helpers.";
    };

    bash = mkOption {
      type = attrsOf unspecified;
      default = { };
      description = "Bash ANSI pill formatting helpers and shell functions.";
    };
  };

  config = mkIf cfg.enable {
    styles.pills = {
      tmux = {
        # Mode pill: solid background, identical cap color on both sides, auto-detected contrast text, no icons
        mode =
          {
            text,
            color,
            fg ? detectContrast color,
            outerBg ? "default",
            bold ? true,
          }:
          let
            boldAttr = if bold then "#,bold" else "";
          in
          "#[fg=${color}#,bg=${outerBg}]${cfg.symbols.left}#[fg=${fg}${boldAttr}#,bg=${color}] ${text} #[fg=${color}#,bg=${outerBg}]${cfg.symbols.right}";

        # Left pill: accent icon badge on left, charcoal body on right
        left =
          {
            icon,
            text,
            accent,
            iconFg ? detectContrast accent,
            outerBg ? "default",
            charcoal ? "brightblack",
            charcoalFg ? "brightwhite",
            boldIcon ? false,
            boldText ? false,
          }:
          let
            boldIconAttr = if boldIcon then "#,bold" else "";
            boldTextAttr = if boldText then "#,bold" else "";
            iconStr = ensureTrailingSpace icon;
          in
          "#[fg=${accent}#,bg=${outerBg}]${cfg.symbols.left}#[fg=${iconFg}${boldIconAttr}#,bg=${accent}]${iconStr}#[fg=${charcoalFg}${boldTextAttr}#,bg=${charcoal}] ${text} #[fg=${charcoal}#,bg=${outerBg}]${cfg.symbols.right}";

        # Right pill: charcoal body on left, accent icon badge on right
        right =
          {
            text,
            icon,
            accent,
            iconFg ? detectContrast accent,
            outerBg ? "default",
            charcoal ? "brightblack",
            charcoalFg ? "brightwhite",
            boldIcon ? false,
            boldText ? false,
          }:
          let
            boldIconAttr = if boldIcon then "#,bold" else "";
            boldTextAttr = if boldText then "#,bold" else "";
            iconStr = ensureLeadingSpace icon;
          in
          "#[fg=${charcoal}#,bg=${outerBg}]${cfg.symbols.left}#[fg=${charcoalFg}${boldTextAttr}#,bg=${charcoal}] ${text} #[fg=${iconFg}${boldIconAttr}#,bg=${accent}]${iconStr}#[fg=${accent}#,bg=${outerBg}]${cfg.symbols.right}";
      };

      lualine = {
        init = ''
          _G.pills = _G.pills or {}

          local function get_contrast_fg(hex, dark_fg, light_fg)
            dark_fg = dark_fg or "#000000"
            light_fg = light_fg or "#ffffff"
            if not hex or type(hex) ~= "string" or #hex < 7 or hex:sub(1, 1) ~= "#" then
              return dark_fg
            end
            local r = tonumber(hex:sub(2, 3), 16) or 0
            local g = tonumber(hex:sub(4, 5), 16) or 0
            local b = tonumber(hex:sub(6, 7), 16) or 0
            local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
            return luminance >= 0.55 and dark_fg or light_fg
          end

          _G.pills.get_contrast_fg = get_contrast_fg

          local function clean_id(s)
            if not s then return "none" end
            return (tostring(s):gsub("[^%w_]", ""))
          end

          -- Mode pill: no icon, solid background, identical cap color on both sides
          _G.pills.mode = function(content, color, bar_bg)
            if not content or content == "" then return "" end
            color = color or "#7677aa"
            bar_bg = bar_bg or "#000000"
            local fg = get_contrast_fg(color, "#000000", "#ffffff")

            local hl_id = "PillMode_" .. clean_id(color) .. "_" .. clean_id(fg) .. "_" .. clean_id(bar_bg)
            vim.api.nvim_set_hl(0, hl_id .. "_Cap",  { fg = color, bg = bar_bg })
            vim.api.nvim_set_hl(0, hl_id .. "_Body", { fg = fg, bg = color, bold = true })

            return string.format("%%#%s_Cap#${cfg.symbols.left}%%#%s_Body# %s %%#%s_Cap#${cfg.symbols.right}",
              hl_id, hl_id, content, hl_id)
          end

          -- Left pill: icon badge on left (accent), content body on right (charcoal)
          _G.pills.left = function(icon, content, accent, bar_bg, content_bg, content_fg)
            if not content or content == "" then return "" end
            accent = accent or "#7677aa"
            bar_bg = bar_bg or "#000000"
            content_bg = content_bg or "${cfg.charcoal}"
            content_fg = content_fg or "${cfg.charcoalFg}"
            local icon_fg = get_contrast_fg(accent, "#000000", "#ffffff")

            local icon_str = tostring(icon or "")
            if not icon_str:match("%s$") then
              icon_str = icon_str .. " "
            end

            local hl_id = "PillLeft_" .. clean_id(accent) .. "_" .. clean_id(content_bg) .. "_" .. clean_id(bar_bg) .. "_" .. clean_id(content_fg) .. "_" .. clean_id(icon_fg)
            vim.api.nvim_set_hl(0, hl_id .. "_LeftCap",  { fg = accent, bg = bar_bg })
            vim.api.nvim_set_hl(0, hl_id .. "_Icon",     { fg = icon_fg, bg = accent })
            vim.api.nvim_set_hl(0, hl_id .. "_Body",     { fg = content_fg, bg = content_bg })
            vim.api.nvim_set_hl(0, hl_id .. "_RightCap", { fg = content_bg, bg = bar_bg })

            return string.format("%%#%s_LeftCap#${cfg.symbols.left}%%#%s_Icon#%s%%#%s_Body# %s %%#%s_RightCap#${cfg.symbols.right}",
              hl_id, hl_id, icon_str, hl_id, content, hl_id)
          end

          -- Right pill: content body on left (charcoal), icon badge on right (accent)
          _G.pills.right = function(content, icon, accent, bar_bg, content_bg, content_fg)
            if not content or content == "" then return "" end
            accent = accent or "#7677aa"
            bar_bg = bar_bg or "#000000"
            content_bg = content_bg or "${cfg.charcoal}"
            content_fg = content_fg or "${cfg.charcoalFg}"
            local icon_fg = get_contrast_fg(accent, "#000000", "#ffffff")

            local icon_str = tostring(icon or "")
            if not icon_str:match("^%s") then
              icon_str = " " .. icon_str
            end

            local hl_id = "PillRight_" .. clean_id(accent) .. "_" .. clean_id(content_bg) .. "_" .. clean_id(bar_bg) .. "_" .. clean_id(content_fg) .. "_" .. clean_id(icon_fg)
            vim.api.nvim_set_hl(0, hl_id .. "_LeftCap",  { fg = content_bg, bg = bar_bg })
            vim.api.nvim_set_hl(0, hl_id .. "_Body",     { fg = content_fg, bg = content_bg })
            vim.api.nvim_set_hl(0, hl_id .. "_Icon",     { fg = icon_fg, bg = accent })
            vim.api.nvim_set_hl(0, hl_id .. "_RightCap", { fg = accent, bg = bar_bg })

            return string.format("%%#%s_LeftCap#${cfg.symbols.left}%%#%s_Body# %s %%#%s_Icon#%s%%#%s_RightCap#${cfg.symbols.right}",
              hl_id, hl_id, content, hl_id, icon_str, hl_id)
          end
        '';
      };

      incline = {
        init = ''
          _G.pills = _G.pills or {}

          local function get_contrast_fg(hex, dark_fg, light_fg)
            if _G.pills.get_contrast_fg then
              return _G.pills.get_contrast_fg(hex, dark_fg, light_fg)
            end
            dark_fg = dark_fg or "#000000"
            light_fg = light_fg or "#ffffff"
            if not hex or type(hex) ~= "string" or #hex < 7 or hex:sub(1, 1) ~= "#" then
              return dark_fg
            end
            local r = tonumber(hex:sub(2, 3), 16) or 0
            local g = tonumber(hex:sub(4, 5), 16) or 0
            local b = tonumber(hex:sub(6, 7), 16) or 0
            local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
            return luminance >= 0.55 and dark_fg or light_fg
          end

          -- Incline pill: returns chunk table { leftCap, iconBadge, contentBody, rightCap }
          _G.pills.incline = {
            left = function(icon, content, accent, content_bg, content_fg, icon_fg)
              if not content or content == "" then return "" end
              accent = accent or "#7677aa"
              content_bg = content_bg or "${cfg.charcoal}"
              content_fg = content_fg or "${cfg.charcoalFg}"
              icon_fg = icon_fg or get_contrast_fg(accent, "#000000", "#ffffff")

              local icon_str = tostring(icon or "")
              if not icon_str:match("%s$") then
                icon_str = icon_str .. " "
              end

              return {
                { "${cfg.symbols.left}", guifg = accent },
                { icon_str, guifg = icon_fg, guibg = accent },
                { " " .. content .. " ", guifg = content_fg, guibg = content_bg },
                { "${cfg.symbols.right}", guifg = content_bg },
              }
            end,

            right = function(content, icon, accent, content_bg, content_fg, icon_fg)
              if not content or content == "" then return "" end
              accent = accent or "#7677aa"
              content_bg = content_bg or "${cfg.charcoal}"
              content_fg = content_fg or "${cfg.charcoalFg}"
              icon_fg = icon_fg or get_contrast_fg(accent, "#000000", "#ffffff")

              local icon_str = tostring(icon or "")
              if not icon_str:match("^%s") then
                icon_str = " " .. icon_str
              end

              return {
                { "${cfg.symbols.left}", guifg = content_bg },
                { " " .. content .. " ", guifg = content_fg, guibg = content_bg },
                { icon_str, guifg = icon_fg, guibg = accent },
                { "${cfg.symbols.right}", guifg = accent },
              }
            end,
          }

          setmetatable(_G.pills.incline, {
            __call = function(_, ...)
              return _G.pills.incline.left(...)
            end,
          })
        '';
      };

      starship = {
        # Mode pill: solid accent badge
        mode =
          {
            text,
            accent,
            fg ? "0",
          }:
          "[${cfg.symbols.left}](${accent})[ ${text} ](bg:${accent} fg:${fg} bold)[${cfg.symbols.right}](${accent})";

        # Left pill: accent icon badge on left, charcoal body on right
        left =
          {
            icon,
            content,
            accent,
            charcoal ? "8",
            charcoalFg ? "15",
            iconFg ? "0",
            extra ? "",
          }:
          let
            iconStr = ensureTrailingSpace icon;
          in
          "[${cfg.symbols.left}](${accent})[${iconStr}](bg:${accent} fg:${iconFg})[ ${content} ](bg:${charcoal} fg:${charcoalFg})${extra}[${cfg.symbols.right}](${charcoal})";

        # Right pill: charcoal body on left, accent icon badge on right
        right =
          {
            content,
            icon,
            accent,
            charcoal ? "8",
            charcoalFg ? "15",
            iconFg ? "0",
            extra ? "",
          }:
          let
            iconStr = ensureLeadingSpace icon;
          in
          "[${cfg.symbols.left}](${charcoal})[ ${content} ](bg:${charcoal} fg:${charcoalFg})${extra}[${iconStr}](bg:${accent} fg:${iconFg})[${cfg.symbols.right}](${accent})";
      };

      pi = {
        # Mode pill: one component so dynamic extensions such as mode-guard
        # keep their value. The statusline renderer supplies the solid body
        # and caps when accent is set.
        mode =
          {
            type ? "text",
            text ? null,
            accent ? "bright-yellow",
            fg ? detectContrast accent,
            bold ? true,
          }:
          {
            inherit type accent fg bold;
            leftCap = cfg.symbols.left;
            rightCap = cfg.symbols.right;
          }
          // lib.optionalAttrs (text != null) { inherit text; };

        # Left pill: accent icon badge on left, charcoal body on right
        left = mkPiPill "left";

        # Right pill: charcoal body on left, accent icon badge on right
        right = mkPiPill "right";
      };

      bash = {
        functions = ''
          pill_load_wallust() {
            declare -gA WALLUST_COLORS=(
              [0]="0;0;0" [1]="224;108;117" [2]="133;180;82" [3]="229;192;123"
              [4]="108;160;220" [5]="179;136;255" [6]="102;194;205" [7]="224;224;224"
              [8]="46;46;46" [9]="238;92;149" [10]="145;71;96" [11]="158;43;75"
              [12]="89;91;214" [13]="238;92;149" [14]="254;43;44" [15]="255;255;255"
            )
            local seq_file="''${WALLUST_SEQUENCES_FILE:-$HOME/.cache/wallust/sequences}"
            if [[ -f "$seq_file" ]]; then
              while IFS= read -r line; do
                while [[ "$line" =~ \]4\;([0-9]+)\;\#([0-9a-fA-F]{6}) ]]; do
                  local slot="''${BASH_REMATCH[1]}"
                  local hex="''${BASH_REMATCH[2]}"
                  local r=$((16#''${hex:0:2}))
                  local g=$((16#''${hex:2:2}))
                  local b=$((16#''${hex:4:2}))
                  WALLUST_COLORS["$slot"]="$r;$g;$b"
                  line="''${line#*\"''${BASH_REMATCH[0]}\"}"
                done
              done < "$seq_file"
            fi
          }

          pill_is_bright() {
            local rgb="$1"
            IFS=';' read -r r g b <<< "$rgb"
            local lum=$(( 299 * r + 587 * g + 114 * b ))
            (( lum >= 140250 ))
          }

          pill_fg() {
            local color="$1"
            if [[ "$color" =~ ^[0-9]+$ ]] && [[ -n "''${WALLUST_COLORS[$color]:-}" ]]; then
              printf "\033[38;2;%sm" "''${WALLUST_COLORS[$color]}"
            elif [[ "$color" =~ ^([0-9]{1,3}\;[0-9]{1,3}\;[0-9]{1,3})$ ]]; then
              printf "\033[38;2;%sm" "$color"
            elif [[ "$color" =~ ^[0-9]+$ ]]; then
              printf "\033[38;5;%sm" "$color"
            fi
          }

          pill_bg() {
            local color="$1"
            if [[ "$color" =~ ^[0-9]+$ ]] && [[ -n "''${WALLUST_COLORS[$color]:-}" ]]; then
              printf "\033[48;2;%sm" "''${WALLUST_COLORS[$color]}"
            elif [[ "$color" =~ ^([0-9]{1,3}\;[0-9]{1,3}\;[0-9]{1,3})$ ]]; then
              printf "\033[48;2;%sm" "$color"
            elif [[ "$color" =~ ^[0-9]+$ ]]; then
              printf "\033[48;5;%sm" "$color"
            fi
          }

          pill_contrast() {
            local color="$1"
            local rgb="''${WALLUST_COLORS[$color]:-$color}"
            if [[ "$rgb" =~ ^([0-9]+)\;([0-9]+)\;([0-9]+)$ ]]; then
              if pill_is_bright "$rgb"; then
                printf "\033[38;2;0;0;0m"
              else
                printf "\033[38;2;255;255;255m"
              fi
            else
              printf "\033[38;5;15m"
            fi
          }

          pill_mode() {
            local text="$1"
            local color="''${2:-10}"
            local left_cap="${cfg.symbols.left}"
            local right_cap="${cfg.symbols.right}"
            printf "%s%s%s%s\033[1m %s \033[0m%s%s\033[0m" \
              "$(pill_fg "$color")" "$left_cap" \
              "$(pill_bg "$color")" "$(pill_contrast "$color")" "$text" \
              "$(pill_fg "$color")" "$right_cap"
          }

          pill_left() {
            local icon="$1"
            local text="$2"
            local accent="''${3:-12}"
            local charcoal="''${4:-8}"
            local charcoal_fg="''${5:-15}"
            local left_cap="${cfg.symbols.left}"
            local right_cap="${cfg.symbols.right}"
            printf "%s%s%s%s%s %s%s %s \033[0m%s%s\033[0m" \
              "$(pill_fg "$accent")" "$left_cap" \
              "$(pill_bg "$accent")" "$(pill_contrast "$accent")" "$icon" \
              "$(pill_bg "$charcoal")" "$(pill_fg "$charcoal_fg")" "$text" \
              "$(pill_fg "$charcoal")" "$right_cap"
          }

          pill_right() {
            local text="$1"
            local icon="$2"
            local accent="''${3:-12}"
            local charcoal="''${4:-8}"
            local charcoal_fg="''${5:-15}"
            local left_cap="${cfg.symbols.left}"
            local right_cap="${cfg.symbols.right}"
            printf "%s%s%s%s %s %s%s %s\033[0m%s%s\033[0m" \
              "$(pill_fg "$charcoal")" "$left_cap" \
              "$(pill_bg "$charcoal")" "$(pill_fg "$charcoal_fg")" "$text" \
              "$(pill_bg "$accent")" "$(pill_contrast "$accent")" "$icon" \
              "$(pill_fg "$accent")" "$right_cap"
          }
        '';
      };
    };
  };
}
