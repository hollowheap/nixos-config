# Editor-oriented toolchain maps, keyed by Neovim filetype.
#
# Only the `linters` block is consumed by home/modules/programs/nvim/lsp.nix
# (vim.diagnostics.nvim-lint.linters_by_ft). The lsp/formatter/debugger
# blocks are reference data for humans and are not wired into nvf; language
# modules remain the ones wiring servers, formatters and most linters. Values
# mirror nvf's language-module defaults so the maps stay truthful.
{
  lsp = {
    bash = [ "bash-language-server" ];
    c = [ "clangd" ];
    cpp = [ "clangd" ];
    json = [ "vscode-json-language-server" ];
    lua = [ "lua-language-server" ];
    nix = [ "nil" ];
    python = [ "basedpyright" ];
    toml = [ "taplo" ];
    typescript = [ "typescript-language-server" ];
    typescriptreact = [ "typescript-language-server" ];
    yaml = [ "yaml-language-server" ];
    zsh = [ "bash-language-server" ];
    markdown = [ "marksman" ];
  };

  formatters = {
    bash = [ "shfmt" ];
    c = [ "clang-format" ];
    cpp = [ "clang-format" ];
    json = [ "jsonfmt" ];
    lua = [ "stylua" ];
    nix = [ "alejandra" ];
    python = [ "black" ];
    toml = [ "taplo" ];
    typescript = [ "prettier" ];
    typescriptreact = [ "prettier" ];
    yaml = [ "prettier" ];
    zsh = [ "shfmt" ];
    markdown = [ "deno" ];
  };

  # Names are nvim-lint linter names: nvf passes its per-language
  # extraDiagnostics provider lists straight into linters_by_ft.
  linters = {
    bash = [ "shellcheck" ];
    c = [ "clangtidy" ];
    cpp = [ "clangtidy" ];
    lua = [ "luacheck" ];
    nix = [
      "statix"
      "deadnix"
    ];
    python = [ "mypy" ];
    toml = [ "tombi" ];
    typescript = [ "eslint_d" ];
    typescriptreact = [ "biomejs" ];
    yaml = [ "yamllint" ];
    zsh = [ "zsh" ];
    markdown = [ "markdownlint-cli2" ];
  };

  debuggers = {
    c = [ "lldb" ];
    cpp = [ "lldb" ];
    python = [ "debugpy" ];
  };
}
