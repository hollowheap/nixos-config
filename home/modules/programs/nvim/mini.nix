{
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    # Provide treesitter textobjects queries (*.scm) on runtimepath so mini.ai
    # can resolve AST nodes (@function, @class, @block, @conditional, @loop)
    # without enabling nvim-treesitter-textobjects' own duplicate keymaps.
    lazy.plugins."nvim-treesitter-textobjects" = {
      lazy = false;
      package = pkgs.vimPlugins.nvim-treesitter-textobjects;
    };

    treesitter.context = {
      enable = true;
      setupOpts = {
        max_lines = 3;
        trim_scope = "outer";
      };
    };

    mini = {
      ai = {
        enable = true;
        setupOpts = {
          n_lines = 500;
          custom_textobjects = {
            f = mkLuaInline "require('mini.ai').gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' })";
            c = mkLuaInline "require('mini.ai').gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' })";
            o = mkLuaInline "require('mini.ai').gen_spec.treesitter({ a = { '@block.outer', '@conditional.outer', '@loop.outer' }, i = { '@block.inner', '@conditional.inner', '@loop.inner' } })";
          };
        };
      };
      bracketed.enable = true;
      comment.enable = false;
      icons.enable = true;
      jump2d.enable = true;
      operators = {
        enable = true;
        setupOpts = {
          evaluate.prefix = "re";
          exchange.prefix = "rx";
          multiply.prefix = "rm";
          replace.prefix = "ro";
          sort.prefix = "rs";
        };
      };
      pairs.enable = true;
      sessions.enable = true;
      surround.enable = true;
      splitjoin = {
        enable = true;
        setupOpts = {
          mappings = {
            toggle = "<leader>lj";
            split = "";
            join = "";
          };
        };
      };
      visits.enable = true;
    };
  };
}
