{
  config,
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  programs.nvf.settings.vim = {
    languages = config.toolchain.nvfLanguages;

    spellcheck = {
      enable = true;
      ignoredFiletypes = config.toolchain.spellcheckIgnoredFiletypes;
    };

    formatter.conform-nvim.setupOpts.formatters_by_ft = config.toolchain.formattersByFt;

    lsp = {
      enable = true;
      formatOnSave = true;
      inlayHints.enable = true;
      lightbulb.enable = true;
      lspkind.enable = true;
      mappings = {
        hover = null;
        renameSymbol = null;
        codeAction = null;
        format = null;
        listReferences = null;
        listImplementations = null;
        listDocumentSymbols = null;
        goToType = null;
        toggleFormatOnSave = null;
        signatureHelp = null;
      };
      servers = {
        nil = config.toolchain.lspServers.nil.settings;
      };
    };

    diagnostics = {
      enable = true;
      config = {
        virtual_text = {
          prefix = "●";
          spacing = 4;
          source = "if_many";
        };
        signs = true;
        underline = true;
        update_in_insert = false;
        severity_sort = true;
      };
      # Consumes config.toolchain.lintersByFt (including yamllint and zsh)
      nvim-lint = {
        enable = true;
        linters_by_ft = config.toolchain.lintersByFt;
      };
    };

    git = {
      gitsigns = {
        enable = true;
        mappings = {
          nextHunk = "]h";
          previousHunk = "[h";
          toggleDeleted = null;
        };
      };
      git-conflict.enable = true;
    };

    autocmds = [
      {
        event = [
          "BufReadPost"
          "InsertLeave"
        ];
        group = "UserAutocmds";
        desc = "Trigger nvim-lint on buffer read and insert leave";
        callback = mkLuaInline ''
          function(ev)
            if _G.nvf_lint and vim.bo[ev.buf].buftype == "" then
              _G.nvf_lint(ev.buf)
            end
          end
        '';
      }
      {
        event = [ "LspAttach" ];
        group = "UserLspKeys";
        desc = "Configure LSP buffer options, delete buffer-local gO, and enable linked editing and inlay hints";
        callback = mkLuaInline ''
          function(ev)
            vim.bo[ev.buf].tagfunc = nil
            vim.bo[ev.buf].omnifunc = nil
            vim.schedule(function()
              if vim.api.nvim_buf_is_valid(ev.buf) then
                pcall(vim.keymap.del, "n", "gO", { buffer = ev.buf })
              end
            end)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client:supports_method("textDocument/linkedEditingRange", ev.buf) then
              vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
            end
            if client and client:supports_method("textDocument/inlayHint", ev.buf) then
              vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
            end
          end
        '';
      }
    ];

    luaConfigRC.lspFeatures = ''
      vim.lsp.codelens.enable()
    '';
  };
}
