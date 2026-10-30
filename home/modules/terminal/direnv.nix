{ ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
    silent = true;
    enableGitIntegration = true;
    config.global.hide_env_diff = true;
  };
}
