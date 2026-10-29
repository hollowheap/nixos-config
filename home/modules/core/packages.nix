{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Development & AI code indexing
    gcc
    gdb
    python3
    uv
    nodejs
    ast-grep
    universal-ctags
    tree-sitter

    # Agent sandboxing
    bubblewrap
  ];
}
