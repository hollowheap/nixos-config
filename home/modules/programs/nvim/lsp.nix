{
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
  editorToolchains = import ../../../lib/toolchains.nix;
in
{
  programs.nvf.settings.vim = {
    languages = {
      enableDAP = true;
      enableExtraDiagnostics = true;
      enableFormat = true;
      enableTreesitter = true;

      bash.enable = true;
      clang.enable = true;
      clang.dap.enable = true;
      json.enable = true;
      lua.enable = true;
      nix.enable = true;
      python.enable = true;
      python.dap.enable = true;
      toml.enable = true;
      tsx.enable = true;
      typescript.enable = true;
      yaml.enable = true;
      zsh.enable = true;
      markdown.enable = true;
      markdown.extensions.markview-nvim.enable = true;
    };

    spellcheck = {
      enable = true;
      ignoredFiletypes = [
        "toggleterm"
        "nix"
        "lua"
        "python"
        "c"
        "cpp"
        "typescript"
        "typescriptreact"
        "yaml"
        "zsh"
        "json"
        "toml"
        "bash"
        "sh"
      ];
    };

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
        nil.nix.flake = {
          autoArchive = true;
          autoEvalInputs = true;
        };
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
      nvim-lint = {
        enable = true;
        linters_by_ft = editorToolchains.linters;
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
        event = [ "LspAttach" ];
        group = "UserLspKeys";
        desc = "Configure LSP buffer options, delete buffer-local gO, and enable linked editing";
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
          end
        '';
      }
      {
        event = [ "LspAttach" ];
        group = "UserAutocmds";
        desc = "Highlight LSP references";
        callback = mkLuaInline ''
          function(ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if not client or not client:supports_method("textDocument/documentHighlight") then
              return
            end
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = ev.buf,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = ev.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        '';
      }
    ];

    luaConfigRC.lspFeatures = ''
      vim.lsp.codelens.enable()
    '';
  };
}
