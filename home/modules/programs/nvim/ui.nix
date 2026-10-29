{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    theme = {
      enable = true;
      base16-colors = {
        base00 = "#000000";
        base01 = "#1a1a1a";
        base02 = "#2e2e2e";
        base03 = "#555555";
        base04 = "#888888";
        base05 = "#e0e0e0";
        base06 = "#eeeeee";
        base07 = "#ffffff";
        base08 = "#ff5555";
        base09 = "#ffaa00";
        base0A = "#ffff55";
        base0B = "#55ff55";
        base0C = "#55ffff";
        base0D = "#5555ff";
        base0E = "#ff55ff";
        base0F = "#aa55ff";
      };
      name = "base16";
    };

    ui = {
      ui2.enable = true;
      borders.enable = true;
      borders.plugins = {
        which-key.enable = true;
      };

      nvim-highlight-colors.enable = true;
      colorful-menu-nvim.enable = true;
      illuminate.enable = true;
      modes-nvim.enable = true;
    };

    visuals = {
      fidget-nvim.enable = true;
      fidget-nvim.setupOpts.notification.override_vim_notify = false;
    };

    statusline.lualine = {
      enable = true;
      setupOpts = {
        options = {
          disabled_filetypes = {
            statusline = [
              "snacks_dashboard"
              "snacks_picker_list"
              "snacks_picker_input"
              "dashboard"
              "alpha"
            ];
          };
          section_separators = {
            left = "";
            right = "";
          };
          component_separators = {
            left = "";
            right = "";
          };
        };
        extensions = lib.mkForce [
          (mkLuaInline ''
            {
              sections = {
                lualine_a = {
                  function()
                    local colors = require("base16-colorscheme").colors
                    local ft = vim.bo.filetype
                    if ft == "AvanteInput" then
                      return _G.pills.left("󰌌", "Input", colors.base0B, colors.base00)
                    elseif ft == "AvanteSelectedCode" then
                      return _G.pills.left("", "Code", colors.base0A, colors.base00)
                    else
                      return _G.pills.left("󰭹", "Chat", colors.base0D, colors.base00)
                    end
                  end
                },
                lualine_b = {},
                lualine_c = {},
                lualine_x = {},
                lualine_y = {},
                lualine_z = {}
              },
              inactive_sections = {
                lualine_a = {
                  function()
                    local colors = require("base16-colorscheme").colors
                    local ft = vim.bo.filetype
                    if ft == "AvanteInput" then
                      return _G.pills.left("󰌌", "Input", colors.base03, colors.base00, colors.base01, colors.base04)
                    elseif ft == "AvanteSelectedCode" then
                      return _G.pills.left("", "Code", colors.base03, colors.base00, colors.base01, colors.base04)
                    else
                      return _G.pills.left("󰭹", "Chat", colors.base03, colors.base00, colors.base01, colors.base04)
                    end
                  end
                },
                lualine_b = {},
                lualine_c = {},
                lualine_x = {},
                lualine_y = {},
                lualine_z = {}
              },
              filetypes = { "Avante", "AvanteInput", "AvanteSelectedCode", "AvanteSelectedFiles", "AvanteTodos" }
            }
          '')
          "quickfix"
        ];
        sections = {
          lualine_a = [
            (mkLuaInline ''
              function()
                local colors = require("base16-colorscheme").colors
                local mode_map = {
                  ['n'] = { name = 'NORMAL', color = colors.base0D },
                  ['no'] = { name = 'O-PENDING', color = colors.base0D },
                  ['nov'] = { name = 'O-PENDING', color = colors.base0D },
                  ['noV'] = { name = 'O-PENDING', color = colors.base0D },
                  ['no\22'] = { name = 'O-PENDING', color = colors.base0D },
                  ['niI'] = { name = 'NORMAL', color = colors.base0D },
                  ['niR'] = { name = 'NORMAL', color = colors.base0D },
                  ['niV'] = { name = 'NORMAL', color = colors.base0D },
                  ['nt'] = { name = 'NORMAL', color = colors.base0D },
                  ['ntT'] = { name = 'NORMAL', color = colors.base0D },
                  ['v'] = { name = 'VISUAL', color = colors.base0E },
                  ['vs'] = { name = 'VISUAL', color = colors.base0E },
                  ['V'] = { name = 'V-LINE', color = colors.base0E },
                  ['Vs'] = { name = 'V-LINE', color = colors.base0E },
                  ['\22'] = { name = 'V-BLOCK', color = colors.base0E },
                  ['\22s'] = { name = 'V-BLOCK', color = colors.base0E },
                  ['s'] = { name = 'SELECT', color = colors.base0E },
                  ['S'] = { name = 'S-LINE', color = colors.base0E },
                  ['\19'] = { name = 'S-BLOCK', color = colors.base0E },
                  ['i'] = { name = 'INSERT', color = colors.base0B },
                  ['ic'] = { name = 'INSERT', color = colors.base0B },
                  ['ix'] = { name = 'INSERT', color = colors.base0B },
                  ['R'] = { name = 'REPLACE', color = colors.base08 },
                  ['Rc'] = { name = 'REPLACE', color = colors.base08 },
                  ['Rx'] = { name = 'REPLACE', color = colors.base08 },
                  ['Rv'] = { name = 'V-REPLACE', color = colors.base08 },
                  ['Rvc'] = { name = 'V-REPLACE', color = colors.base08 },
                  ['Rvx'] = { name = 'V-REPLACE', color = colors.base08 },
                  ['c'] = { name = 'COMMAND', color = colors.base0A },
                  ['cv'] = { name = 'EX', color = colors.base0A },
                  ['ce'] = { name = 'EX', color = colors.base0A },
                  ['r'] = { name = 'PROMPT', color = colors.base0C },
                  ['rm'] = { name = 'MORE', color = colors.base0C },
                  ['r?'] = { name = 'CONFIRM', color = colors.base0C },
                  ['!'] = { name = 'SHELL', color = colors.base08 },
                  ['t'] = { name = 'TERMINAL', color = colors.base0D },
                }
                local mode = vim.api.nvim_get_mode().mode
                local info = mode_map[mode] or { name = mode, color = colors.base0D }
                return _G.pills.mode(info.name, info.color, colors.base00)
              end
            '')
          ];
          lualine_b = [
            {
              "@1" = mkLuaInline ''
                function()
                  local colors = require("base16-colorscheme").colors
                  local branch = vim.b.gitsigns_head or vim.g.loaded_fugitive and vim.fn.FugitiveHead() or ""
                  if branch == "" then
                    local ok, head = pcall(function() return vim.fn.system("git rev-parse --abbrev-ref HEAD 2>/dev/null"):gsub("\n", "") end)
                    if ok and head ~= "" and not head:find("fatal") then branch = head end
                  end
                  if branch == "" then return "" end
                  return _G.pills.left("", branch, colors.base0E, colors.base00)
                end
              '';
              on_click = mkLuaInline ''
                function()
                  Snacks.picker.git_branches()
                end
              '';
            }
          ];
          lualine_c = [
            {
              "@1" = "diff";
              colored = false;
              symbols = {
                added = "+ ";
                modified = "~ ";
                removed = "- ";
              };
            }
            [ "diagnostics" ]
          ];
          lualine_x = [
            (mkLuaInline ''
              function()
                if vim.v.hlsearch == 0 then return "" end
                local colors = require("base16-colorscheme").colors
                local s = vim.fn.searchcount({ recompute = 1, maxcount = 999 })
                if not s or s.total == 0 then return "" end
                return _G.pills.right(string.format("%d/%d", s.current, s.total), "", colors.base0A, colors.base00)
              end
            '')
          ];
          lualine_y = [ ];
          lualine_z = [ ];
        };
        inactive_sections = {
          lualine_a = [ ];
          lualine_b = [ ];
          lualine_c = [ ];
          lualine_x = [ ];
          lualine_y = [ ];
          lualine_z = [ ];
        };
      };
    };

    lazy.plugins = {
      "incline.nvim" = {
        lazy = false;
        package = pkgs.vimPlugins.incline-nvim;
        setupModule = "incline";
        setupOpts = {
          hide = {
            cursorline = false;
            focused_win = false;
            only_win = false;
          };
          ignore = {
            buftypes = "special";
            filetypes = [
              "snacks_dashboard"
              "snacks_picker_list"
              "snacks_picker_input"
              "dashboard"
              "alpha"
              "help"
            ];
            floating_wins = true;
            unlisted_buffers = true;
            wintypes = "special";
          };
          window = {
            padding = 0;
            margin = {
              horizontal = 1;
              vertical = 0;
            };
            placement = {
              horizontal = "right";
              vertical = "top";
            };
            options = {
              signcolumn = "no";
              wrap = false;
            };
            winhighlight = {
              active = {
                EndOfBuffer = "None";
                Normal = "Normal";
                Search = "None";
              };
              inactive = {
                EndOfBuffer = "None";
                Normal = "NormalNC";
                Search = "None";
              };
            };
          };
          render = mkLuaInline ''
            function(props)
              local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
              if fname == "" then fname = "[No Name]" end

              local icon = "󰈚"
              local ok, mini_icons = pcall(require, "mini.icons")
              if ok then
                local i = mini_icons.get("file", fname)
                if i and i ~= "" then icon = i end
              end

              if vim.bo[props.buf].modified then fname = fname .. " " end
              if vim.bo[props.buf].readonly then fname = fname .. " " end

              local colors = require("base16-colorscheme").colors
              local accent = props.focused and colors.base0D or colors.base03
              local content_bg = props.focused and "${config.styles.pills.charcoal}" or colors.base01
              local content_fg = props.focused and "${config.styles.pills.charcoalFg}" or colors.base04

              return _G.pills.incline.left(icon, fname, accent, content_bg, content_fg)
            end
          '';
        };
      };
    };

    luaConfigRC.wallustAndLualine = ''
      package.path = package.path .. ";" .. vim.fn.expand("~/.config/nvf/lua/?.lua")
      local ok, wallust = pcall(require, "wallust")
      if ok then
        wallust.setup()
      end

      ${config.styles.pills.lualine.init}
      ${config.styles.pills.incline.init}
      _G.mk_pill = _G.pills.left

      _G.update_lualine_theme = function()
        local colors = require("base16-colorscheme").colors
        local lualine_theme = {
          normal = {
            a = { fg = colors.base07, bg = colors.base00 },
            b = { fg = colors.base07, bg = colors.base00 },
            c = { fg = colors.base05, bg = colors.base00 },

            x = { fg = colors.base07, bg = colors.base00 },
            y = { fg = colors.base07, bg = colors.base00 },
            z = { fg = colors.base07, bg = colors.base00 },
          },
          insert = { a = { fg = colors.base07, bg = colors.base00 } },
          visual = { a = { fg = colors.base07, bg = colors.base00 } },
          replace = { a = { fg = colors.base07, bg = colors.base00 } },
          command = { a = { fg = colors.base07, bg = colors.base00 } },

          inactive = {
            a = { fg = colors.base07, bg = colors.base00 },
            b = { fg = colors.base07, bg = colors.base00 },
            c = { fg = colors.base07, bg = colors.base00 },

            x = { fg = colors.base07, bg = colors.base00 },
            y = { fg = colors.base07, bg = colors.base00 },
            z = { fg = colors.base07, bg = colors.base00 },
          },
        }
        local ok_l, lualine = pcall(require, "lualine")
        if ok_l then
          local cfg = lualine.get_config()
          cfg.options = cfg.options or {}
          cfg.options.theme = lualine_theme
          cfg.options.section_separators = ""
          cfg.options.component_separators = ""
          lualine.setup(cfg)
        end
      end

      _G.update_lualine_theme()
    '';
  };

  programs.wallust.settings = {
    templates.nvim = {
      template = "nvim-colors.lua";
      target = "${config.home.homeDirectory}/.config/nvf/lua/wallust.lua";
    };
    hooks.nvim = "${pkgs.procps}/bin/pkill -SIGUSR1 nvim || true";
  };
}
