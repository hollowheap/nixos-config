{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  programs = {
    nvf = {
      enable = true;
      defaultEditor = true;

      settings.vim = {
        luaConfigPre = ''
          _G._nvim_start_hrtime = vim.uv.hrtime()
        '';

        extraPackages = [
          pkgs.yamllint
          pkgs.trash-cli
          pkgs.wl-clipboard
        ];

        lazy.plugins = with pkgs.vimPlugins; {
          "tiny-cmdline.nvim" = {
            lazy = false;
            package = tiny-cmdline-nvim;
            setupModule = "tiny-cmdline";
            setupOpts = { };
          };
          "helpview.nvim" = {
            ft = [ "help" ];
            lazy = true;
            package = helpview-nvim;
          };
          "mega.cmdparse" = {
            lazy = true;
            package = mega-cmdparse;
          };
          "mega.logging" = {
            lazy = true;
            package = mega-logging;
          };
          "tiny-glimmer.nvim" = {
            lazy = false;
            package = pkgs.vimPlugins.tiny-glimmer-nvim;
            setupModule = "tiny-glimmer";
            setupOpts = { };
          };
        };

        undoFile.enable = true;

        hideSearchHighlight = true;

        lineNumberMode = "relNumber";
        syntaxHighlighting = true;

        globals = {
          mapleader = " ";
          maplocalleader = "\\\\";
        };

        options = {
          compatible = false;

          breakindent = true;
          cursorline = true;
          linebreak = true;
          number = true;
          splitbelow = true;
          splitright = true;

          ruler = true;
          showmode = false;
          showcmd = true;
          wrap = true;

          fillchars = "eob: ";

          incsearch = true;

          ignorecase = true;
          infercase = true;
          smartcase = true;

          smartindent = true;

          completeopt = "menuone,noinsert,popup";
          virtualedit = "block";
          formatoptions = "qjl1";

          tabstop = 2;
          softtabstop = 2;
          expandtab = true;

          shiftwidth = 2;
          shiftround = true;

          copyindent = true;

          showmatch = true;

          scrolloff = 4;

          updatetime = 300;
          hlsearch = true;

          cmdheight = 0;

          mouse = "a";

          conceallevel = 2;

          listchars = "tab:> ,nbsp:␣,space: ,trail:·,precedes:…,extends:…";
          list = true;

          display = "lastline,truncate";

          pumheight = 10;
        };

        luaConfigRC.clipboard = ''
          if vim.env.WAYLAND_DISPLAY then
            vim.o.clipboard = "unnamedplus"
          elseif vim.env.SSH_TTY then
            vim.g.clipboard = "osc52"
          end
        '';

        augroups = [
          { name = "UserAutocmds"; }
          { name = "UserLspKeys"; }
        ];

        autocmds = [
          {
            event = [ "BufReadPost" ];
            group = "UserAutocmds";
            desc = "Restore last cursor position";
            callback = mkLuaInline ''
              function(ev)
                if vim.bo[ev.buf].buftype ~= "" then
                  return
                end
                local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
                local count = vim.api.nvim_buf_line_count(ev.buf)
                if mark[1] > 0 and mark[1] <= count then
                  pcall(vim.api.nvim_win_set_cursor, 0, mark)
                end
              end
            '';
          }
        ];
      };
    };

  };
  home.sessionVariables.VISUAL = "nvim";
}
