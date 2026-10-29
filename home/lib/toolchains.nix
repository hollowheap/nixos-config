# Editor-oriented toolchain maps, keyed by Neovim filetype.
#
# This is separate from the `toolchains` package lists in flake.nix (which
# feed devShells and are passed via extraSpecialArgs): those answer "what
# binaries", these answer "which lsp/linter/formatter/debugger per
# filetype". Values mirror nvf's language-module defaults so the maps stay
# truthful; language modules themselves remain the ones wiring servers,
# formatters and most linters.
{
  lsp = {
    c = [ "clangd" ];
    cpp = [ "clangd" ];
    nix = [ "nil" ];
    python = [ "basedpyright" ];
    typescript = [ "typescript-language-server" ];
    typescriptreact = [ "typescript-language-server" ];
    yaml = [ "yaml-language-server" ];
    zsh = [ "bash-language-server" ];
    markdown = [ "marksman" ];
  };

  formatters = {
    c = [ "clang-format" ];
    cpp = [ "clang-format" ];
    nix = [ "alejandra" ];
    python = [ "black" ];
    typescript = [ "prettier" ];
    typescriptreact = [ "prettier" ];
    yaml = [ "prettier" ];
    zsh = [ "shfmt" ];
    markdown = [ "deno" ];
  };

  # Names are nvim-lint linter names: nvf passes its per-language
  # extraDiagnostics provider lists straight into linters_by_ft.
  linters = {
    c = [ "clangtidy" ];
    cpp = [ "clangtidy" ];
    nix = [
      "statix"
      "deadnix"
    ];
    python = [ "mypy" ];
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
