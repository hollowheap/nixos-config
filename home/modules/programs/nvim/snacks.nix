{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    utility = {
      smart-splits.enable = true;
      grug-far-nvim.enable = true;
      snacks-nvim = {
        enable = true;
        setupOpts = {
          dashboard = {
            enabled = true;
            width = 80;
            preset.keys = [
              {
                icon = " ";
                key = "f";
                desc = "Find File";
                action = ":lua Snacks.dashboard.pick('files')";
              }
              {
                icon = " ";
                key = "e";
                desc = "Explorer";
                action = ":lua Snacks.explorer()";
              }
              {
                icon = " ";
                key = "n";
                desc = "New File";
                action = ":ene | startinsert";
              }
              {
                icon = " ";
                key = "g";
                desc = "Find Text";
                action = ":lua Snacks.dashboard.pick('live_grep')";
              }
              {
                icon = " ";
                key = "r";
                desc = "Recent Files";
                action = ":lua Snacks.dashboard.pick('oldfiles')";
              }
              {
                icon = " ";
                key = "s";
                desc = "Restore Session";
                section = "session";
              }
              {
                icon = " ";
                key = "q";
                desc = "Quit";
                action = ":qa";
              }
            ];
            sections = [
              {
                section = "terminal";
                cmd = "${pkgs.hollowheap-colorscript}/bin/hollowheap-colorscript";
                align = "center";
                height = 8;
              }
              {
                icon = " ";
                title = "Git Status";
                ttl = 300;
                indent = 2;
                padding = 1;
                section = "terminal";
                enabled = mkLuaInline "function() return Snacks.git.get_root() ~= nil end";
                cmd = "git --no-pager diff --stat -B -M -C";
                height = 10;
              }
              {
                section = "keys";
                gap = 1;
              }
              {
                section = "startup";
              }
            ];
          };
          explorer = {
            enabled = true;
            replace_netrw = true;
            trash = true;
          };
          indent = {
            enabled = true;
            scope = {
              enabled = true;
            };
          };
          notifier = {
            enabled = true;
          };
          zen = {
            enabled = true;
          };
          dim = {
            enabled = true;
          };
          bigfile = {
            enabled = true;
          };
          quickfile = {
            enabled = true;
          };
          rename = {
            enabled = true;
          };
          input = {
            enabled = true;
          };
          picker = {
            enabled = true;
            ui_select = true;
          };
          statuscolumn = {
            enabled = true;
          };
          scroll = {
            enabled = true;
          };
          notify = {
            enabled = true;
          };
          profiler = {
            enabled = true;
          };
          words = {
            enabled = true;
          };
        };
      };
    };

    autocmds = [
      {
        event = [
          "UIEnter"
          "VimEnter"
        ];
        once = true;
        group = "UserAutocmds";
        desc = "Record elapsed startup time in milliseconds";
        callback = mkLuaInline ''
          function()
            if not _G.lazy_startup_time then
              local start = _G._nvim_start_hrtime or vim.uv.hrtime()
              _G.lazy_startup_time = math.floor(((vim.uv.hrtime() - start) / 1e6) * 100 + 0.5) / 100
            end
          end
        '';
      }
      {
        event = [ "FileType" ];
        pattern = [ "snacks_picker_list" ];
        group = "UserAutocmds";
        desc = "Set nowait on buffer-local r in Snacks explorer/picker list";
        callback = mkLuaInline ''
          function(ev)
            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(ev.buf) then return end
              for _, m in ipairs(vim.api.nvim_buf_get_keymap(ev.buf, "n")) do
                if m.lhs == "r" and m.nowait == 0 then
                  vim.keymap.set("n", "r", m.callback or m.rhs, {
                    buffer = ev.buf,
                    expr = m.expr == 1,
                    remap = m.noremap == 0,
                    silent = m.silent == 1,
                    nowait = true,
                    desc = m.desc,
                  })
                  break
                end
              end
            end)
          end
        '';
      }
    ];

    luaConfigRC.startupStats = ''
      package.preload["lazy.stats"] = function()
        return {
          stats = function()
            local start = _G._nvim_start_hrtime or vim.uv.hrtime()
            local elapsed = _G.lazy_startup_time or (math.floor(((vim.uv.hrtime() - start) / 1e6) * 100 + 0.5) / 100)
            return {
              startuptime = elapsed,
              count = #vim.fn.globpath(vim.o.packpath, "pack/*/*/*", 0, 1),
              loaded = #vim.fn.globpath(vim.o.packpath, "pack/*/start/*", 0, 1),
            }
          end,
        }
      end
    '';
  };
}
