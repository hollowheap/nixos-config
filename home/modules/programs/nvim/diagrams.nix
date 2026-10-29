{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    extraPackages = [
      pkgs.imagemagick
      pkgs.mermaid-cli
      pkgs.plantuml
      pkgs.d2
      pkgs.graphviz
    ];

    lazy.plugins = {
      "diagram.nvim" = {
        lazy = true;
        ft = [
          "markdown"
          "norg"
        ];
        package = pkgs.vimPlugins.diagram-nvim;
        setupModule = "diagram";
        setupOpts = {
          renderer_options = {
            mermaid = {
              background = "transparent";
              theme = "dark";
            };
            plantuml = {
              charset = "utf-8";
            };
            d2 = {
              theme_id = 1;
            };
          };
        };
      };
    };

    utility.images.image-nvim = {
      enable = true;
      setupOpts = {
        backend = "kitty";
        processor = "magick_cli";
        integrations = {
          markdown = {
            enabled = true;
            clear_in_insert_mode = false;
            download_remote_images = true;
            only_render_image_at_cursor = false;
            floating_windows = false;
          };
        };
        max_width_window_percentage = 100;
        max_height_window_percentage = 50;
        window_overlap_clear_enabled = false;
        window_overlap_clear_ft_ignore = [
          "cmp_menu"
          "cmp_docs"
          "snacks_notif"
          "scrollview"
          "scrollview_sign"
        ];
      };
    };

    binds.whichKey.register = {
      "<leader>m" = "+Media/Diagrams";
      "<leader>mr" = "Render diagrams";
      "<leader>mc" = "Clear diagrams";
      "<leader>mh" = "Diagram hover preview";
    };

    keymaps = [
      {
        key = "<leader>mr";
        lua = true;
        action = "function() require('diagram').render() end";
        mode = "n";
        desc = "Render diagrams";
      }
      {
        key = "<leader>mc";
        lua = true;
        action = "function() require('diagram').clear() end";
        mode = "n";
        desc = "Clear diagrams";
      }
      {
        key = "<leader>mh";
        lua = true;
        action = "function() require('diagram').show_diagram_hover() end";
        mode = "n";
        desc = "Diagram hover preview";
      }
    ];
  };
}
