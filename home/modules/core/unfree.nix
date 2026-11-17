{lib, ...}: {
  options.unfreePackages = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "claude-code"
      "antigravity-cli"
      "codex"
      "crush"
      "diagram.nvim"
      "github-copilot-cli"
      "kiro-cli"
      "kiro-cli-unwrapped"
    ];
    description = "Package names allowed to build with an unfree license.";
  };
}
