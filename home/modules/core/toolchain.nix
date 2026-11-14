{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.toolchain = {
    packages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Unified LSP, formatter, linter, and DAP packages exposed globally on PATH.";
    };

    nvfLanguages = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Declarative language toolchain flags consumed by nvf.";
    };

    lspServers = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Canonical LSP server definitions shared across editors and AI harnesses.";
    };

    formattersByFt = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Formatter overrides per filetype consumed by conform-nvim.";
    };

    lintersByFt = mkOption {
      type = types.attrsOf (types.listOf types.str);
      default = { };
      description = "Extra linter overrides per filetype consumed by nvim-lint.";
    };

    spellcheckIgnoredFiletypes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Code filetypes excluded from prose spellcheck.";
    };

    crushLsp = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "LSP server map formatted for Charm Crush settings.lsp.";
    };

    opencodeLsp = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "LSP server map formatted for OpenCode settings.lsp.";
    };

    opencodeFormatters = mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Formatter map formatted for OpenCode settings.formatter.";
    };
  };

  config = {
    toolchain = {
      packages = with pkgs; [
        # Nix
        nil
        alejandra
        statix
        deadnix

        # Lua
        lua-language-server
        stylua
        luajitPackages.luacheck

        # Python
        basedpyright
        black
        mypy
        python3Packages.debugpy

        # TypeScript / JavaScript / Web
        typescript-language-server
        prettier
        eslint_d
        biome

        # C / C++
        clang-tools
        lldb

        # Shell (Bash / Zsh)
        bash-language-server
        shellcheck
        shfmt

        # Data & Prose (JSON / YAML / TOML / Markdown)
        vscode-langservers-extracted
        jsonfmt
        yaml-language-server
        yamllint
        taplo
        tombi
        marksman
        markdownlint-cli2
        deno
      ];

      nvfLanguages = {
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
        markdown.extensions.render-markdown-nvim.enable = true;
      };

      lspServers = {
        nil = {
          command = "nil";
          args = [ ];
          extensions = [ ".nix" ];
          settings = {
            nix.flake = {
              autoArchive = true;
              autoEvalInputs = true;
            };
          };
        };
        lua_ls = {
          command = "lua-language-server";
          args = [ ];
          extensions = [ ".lua" ];
        };
        basedpyright = {
          command = "basedpyright-langserver";
          args = [ "--stdio" ];
          extensions = [
            ".py"
            ".pyi"
          ];
        };
        ts_ls = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
          extensions = [
            ".ts"
            ".tsx"
            ".js"
            ".jsx"
          ];
        };
        clangd = {
          command = "clangd";
          args = [ ];
          extensions = [
            ".c"
            ".cpp"
            ".cc"
            ".h"
            ".hpp"
          ];
        };
        bashls = {
          command = "bash-language-server";
          args = [ "start" ];
          extensions = [
            ".sh"
            ".bash"
            ".zsh"
          ];
        };
        jsonls = {
          command = "vscode-json-language-server";
          args = [ "--stdio" ];
          extensions = [
            ".json"
            ".jsonc"
          ];
        };
        yamlls = {
          command = "yaml-language-server";
          args = [ "--stdio" ];
          extensions = [
            ".yaml"
            ".yml"
          ];
        };
        taplo = {
          command = "taplo";
          args = [
            "lsp"
            "stdio"
          ];
          extensions = [ ".toml" ];
        };
        marksman = {
          command = "marksman";
          args = [ "server" ];
          extensions = [
            ".md"
            ".markdown"
          ];
        };
      };

      formattersByFt = {
        markdown = lib.mkForce [ ];
      };

      lintersByFt = {
        yaml = [ "yamllint" ];
        zsh = [ "zsh" ];
      };

      spellcheckIgnoredFiletypes = [
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

      crushLsp = lib.mapAttrs (_name: srv: {
        inherit (srv) command;
      } // lib.optionalAttrs (srv.args != [ ]) {
        inherit (srv) args;
      }) config.toolchain.lspServers;

      opencodeLsp = lib.mapAttrs (_name: srv: {
        command = [ srv.command ] ++ srv.args;
        inherit (srv) extensions;
      }) config.toolchain.lspServers;

      opencodeFormatters = {
        alejandra = {
          command = [
            "alejandra"
            "$FILE"
          ];
          extensions = [ ".nix" ];
        };
        stylua = {
          command = [
            "stylua"
            "$FILE"
          ];
          extensions = [ ".lua" ];
        };
        black = {
          command = [
            "black"
            "--quiet"
            "$FILE"
          ];
          extensions = [ ".py" ];
        };
        shfmt = {
          command = [
            "shfmt"
            "-w"
            "$FILE"
          ];
          extensions = [
            ".sh"
            ".bash"
          ];
        };
        clang-format = {
          command = [
            "clang-format"
            "-i"
            "$FILE"
          ];
          extensions = [
            ".c"
            ".cpp"
            ".h"
            ".hpp"
          ];
        };
        tombi = {
          command = [
            "tombi"
            "format"
            "$FILE"
          ];
          extensions = [ ".toml" ];
        };
      };
    };

    home.packages = config.toolchain.packages;
  };
}
