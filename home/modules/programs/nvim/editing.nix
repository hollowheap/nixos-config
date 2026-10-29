{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    lazy.plugins = {
      "boole.nvim" = {
        lazy = false;
        package = pkgs.vimPlugins.boole-nvim;
        setupModule = "boole";
        setupOpts = {
          mappings = {
            increment = "<C-a>";
            decrement = "<C-x>";
          };
        };
      };
      "highlight-undo.nvim" = {
        lazy = false;
        package = pkgs.vimPlugins.highlight-undo-nvim;
        setupModule = "highlight-undo";
        setupOpts = {
          duration = 300;
          hlgroup = "HighlightUndo";
        };
      };
    };
  };
}
