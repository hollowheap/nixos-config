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
    };
  };
}
