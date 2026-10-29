{
  pkgs,
  ...
}:
{
  programs.nvf.settings.vim = {
    lazy.plugins = {
      "blink.compat" = {
        lazy = false;
        package = pkgs.vimPlugins.blink-compat;
        setupModule = "blink.compat";
        setupOpts = { };
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
          disable_keymaps = true;
          disable_inline_completion = false;
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
          default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
            "supermaven"
            "avante"
          ];
          providers = {
            supermaven = {
              name = "supermaven";
              module = "blink.compat.source";
              score_offset = 100;
              async = true;
            };
            avante = {
              module = "blink-cmp-avante";
              name = "Avante";
              opts = { };
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
