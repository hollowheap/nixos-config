{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    lazy.plugins = {
      "goto-preview" = {
        lazy = false;
        package = pkgs.vimPlugins.goto-preview;
        setupModule = "goto-preview";
        setupOpts = {
          default_mappings = false;
          resizing_mappings = true;
          focus_on_open = true;
          references = {
            provider = "snacks";
          };
        };
      };
    };

    binds.whichKey.register = {
      "<leader>lp" = "+Preview";
      "<leader>lpd" = "Preview definition";
      "<leader>lpt" = "Preview type definition";
      "<leader>lpi" = "Preview implementation";
      "<leader>lpr" = "Preview references";
      "<leader>lpq" = "Close preview windows";
    };

    keymaps = [
      {
        key = "<leader>lpd";
        lua = true;
        action = "function() require('goto-preview').goto_preview_definition() end";
        mode = "n";
        desc = "Preview definition";
      }
      {
        key = "<leader>lpt";
        lua = true;
        action = "function() require('goto-preview').goto_preview_type_definition() end";
        mode = "n";
        desc = "Preview type definition";
      }
      {
        key = "<leader>lpi";
        lua = true;
        action = "function() require('goto-preview').goto_preview_implementation() end";
        mode = "n";
        desc = "Preview implementation";
      }
      {
        key = "<leader>lpr";
        lua = true;
        action = "function() require('goto-preview').goto_preview_references() end";
        mode = "n";
        desc = "Preview references";
      }
      {
        key = "<leader>lpq";
        lua = true;
        action = "function() require('goto-preview').close_all_win() end";
        mode = "n";
        desc = "Close preview windows";
      }
      {
        key = "gpd";
        lua = true;
        action = "function() require('goto-preview').goto_preview_definition() end";
        mode = "n";
        desc = "Preview definition";
      }
      {
        key = "gpt";
        lua = true;
        action = "function() require('goto-preview').goto_preview_type_definition() end";
        mode = "n";
        desc = "Preview type definition";
      }
      {
        key = "gpi";
        lua = true;
        action = "function() require('goto-preview').goto_preview_implementation() end";
        mode = "n";
        desc = "Preview implementation";
      }
      {
        key = "gpr";
        lua = true;
        action = "function() require('goto-preview').goto_preview_references() end";
        mode = "n";
        desc = "Preview references";
      }
      {
        key = "gP";
        lua = true;
        action = "function() require('goto-preview').close_all_win() end";
        mode = "n";
        desc = "Close preview windows";
      }
    ];
  };
}
