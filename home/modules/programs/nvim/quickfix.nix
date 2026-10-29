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
    lazy.plugins = {
      "quicker.nvim" = {
        lazy = false;
        package = pkgs.vimPlugins.quicker-nvim;
        setupModule = "quicker";
        setupOpts = {
          opts = {
            buflisted = false;
            number = false;
            relativenumber = false;
            signcolumn = "auto";
            winfixheight = true;
            wrap = false;
          };
          keys = mkLuaInline ''
            {
              {
                ">",
                function()
                  require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
                end,
                desc = "Expand quickfix context",
              },
              {
                "<",
                function()
                  require("quicker").collapse()
                end,
                desc = "Collapse quickfix context",
              },
            }
          '';
        };
      };
    };

    binds.whichKey.register = {
      "<leader>tq" = "Toggle Quickfix [quicker]";
      "<leader>tl" = "Toggle Loclist [quicker]";
    };

    keymaps = [
      {
        key = "<leader>tq";
        lua = true;
        action = "function() require('quicker').toggle() end";
        mode = "n";
        desc = "Toggle Quickfix [quicker]";
      }
      {
        key = "<leader>tl";
        lua = true;
        action = "function() require('quicker').toggle({ loclist = true }) end";
        mode = "n";
        desc = "Toggle Loclist [quicker]";
      }
    ];
  };
}
