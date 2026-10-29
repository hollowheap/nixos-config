{ ... }:
{
  programs.nvf.settings.vim.mini = {
    ai.enable = true;
    bracketed.enable = true;
    comment.enable = false;
    hipatterns.enable = true;
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
}
