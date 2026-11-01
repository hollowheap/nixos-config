{ config, lib, ... }:
let
  pills = config.styles.pills.starship;

  noRuntimeModules = [
    "buf"
    "bun"
    "c"
    "cmake"
    "cobol"
    "cpp"
    "crystal"
    "daml"
    "dart"
    "deno"
    "dotnet"
    "elixir"
    "elm"
    "erlang"
    "fennel"
    "fortran"
    "gleam"
    "golang"
    "gradle"
    "haskell"
    "haxe"
    "helm"
    "java"
    "julia"
    "kotlin"
    "lua"
    "maven"
    "meson"
    "mojo"
    "nim"
    "nodejs"
    "ocaml"
    "odin"
    "opa"
    "perl"
    "php"
    "pixi"
    "pulumi"
    "purescript"
    "python"
    "quarto"
    "raku"
    "red"
    "rlang"
    "ruby"
    "rust"
    "scala"
    "solidity"
    "swift"
    "typst"
    "vagrant"
    "vlang"
    "xmake"
    "zig"
  ];

  runtimePillSettings = lib.genAttrs noRuntimeModules (_: {
    style = "4";
    format = pills.mode { text = "$symbol"; accent = "$style"; } + " ";
  });
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = runtimePillSettings // {
      format = lib.concatStrings [
        "$username"
        "$directory"
        "$character"
      ];
      right_format = "$git_branch$git_status$nix_shell$cmd_duration";
      add_newline = false;
      fill.symbol = " ";
      line_break.disabled = true;

      character = {
        success_symbol = "[◎](bold italic fg:11)";
        error_symbol = "[○](italic fg:5)";
        vimcmd_symbol = "[■](italic dimmed fg:2)";
      };

      directory = {
        style = "4";
        format = pills.left {
          icon = "󰉋";
          content = "$path";
          accent = "$style";
          extra = "[$read_only](bg:8 fg:9)";
        } + " ";
        truncation_length = 4;
        read_only = "󰌾 ";
      };

      git_branch = {
        format = pills.right {
          icon = "";
          content = "$branch";
          accent = "6";
        } + " ";
      };

      git_status = {
        format = "\\(" + pills.right {
          icon = "󰊢";
          content = "$all_status$ahead_behind";
          accent = "11";
        } + " \\)";
        staged = "[+](bg:8 fg:10)";
        modified = "[!](bg:8 fg:11)";
        renamed = "[»](bg:8 fg:12)";
        deleted = "[-](bg:8 fg:9)";
        untracked = "[?](bg:8 fg:9)";
        stashed = "[≡](bg:8 fg:13)";
        conflicted = "[✖](bg:8 fg:9 bold)";

        ahead = "[↑$count](bg:8 fg:14)";
        behind = "[↓$count](bg:8 fg:9)";
        diverged = "[↕ ↑$ahead_count ↓$behind_count](bg:8 fg:13)";
      };

      cmd_duration = {
        format = pills.right {
          icon = "󱑂";
          content = "$duration";
          accent = "4";
        } + " ";
      };

      nix_shell = {
        format = pills.right {
          icon = "";
          content = "$state";
          accent = "4";
        } + " ";
      };

      package = {
        symbol = "󰏗 ";
        format = pills.mode {
          text = "$symbol";
          accent = "5";
        } + " ";
      };
    };
  };
}
