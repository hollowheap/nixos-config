{
  lib,
  pkgs,
  ...
}:
{
  programs.nvf.settings.vim = {
    luaConfigRC.blinkCompatPreload = lib.hm.dag.entryBefore [ "lazyConfigs" ] ''
      package.preload["cmp"] = function()
        return require("blink.compat")
      end
    '';

    lazy.plugins = {
      "blink.compat" = {
        lazy = false;
        package = pkgs.vimPlugins.blink-compat;
        setupModule = "blink.compat";
        setupOpts = { };
      };
      "supermaven-nvim" = {
        event = [ "InsertEnter" ];
      };
    };

    assistant = {
      avante-nvim.enable = true;
      avante-nvim.setupOpts = {
        provider = "pi";
        mode = "agentic";
        behaviour = {
          auto_suggestions = false;
        };
        acp_providers = {
          pi = {
            command = "${pkgs.nodejs}/bin/node";
            args = [ "/home/hollowheap/repos/my-pi-agent/packages/pi-acp/dist/main.js" ];
            env = { };
          };
        };
      };

      supermaven-nvim = {
        enable = true;
        setupOpts = {
          disable_keymaps = false;
          disable_inline_completion = false;
          keymaps = {
            accept_suggestion = "<M-l>";
            clear_suggestion = "<C-]>";
            accept_word = "<M-w>";
          };
        };
      };
    };

    autocomplete.blink-cmp = {
      enable = true;
      mappings = {
        previous = null;
        next = null;
        confirm = null;
        complete = null;
        close = null;
        scrollDocsUp = null;
        scrollDocsDown = null;
      };
      setupOpts = {
        keymap = {
          preset = "super-tab";
          "<Esc>" = [
            "cancel"
            "fallback"
          ];
        };
        sources = {
          default = lib.mkForce [
            "lsp"
            "path"
            "snippets"
            "buffer"
            "supermaven"
            "blink-cmp-avante"
          ];
          providers = {
            supermaven = {
              name = "supermaven";
              module = "blink.compat.source";
              score_offset = 100;
              async = true;
            };
          };
        };
        completion = {
          list.selection = {
            preselect = true;
            auto_insert = true;
          };
          ghost_text.enabled = false;
          documentation = {
            auto_show = true;
            auto_show_delay_ms = 200;
          };
          menu = {
            auto_show = true;
          };
        };
      };
      sourcePlugins = {
        blink-cmp-avante = {
          enable = true;
          module = "blink-cmp-avante";
          package = pkgs.vimPlugins.blink-cmp-avante;
        };
      };
    };
  };
}
