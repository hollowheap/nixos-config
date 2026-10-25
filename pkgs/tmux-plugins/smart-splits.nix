{
  lib,
  fetchFromGitHub,
  tmuxPlugins,
}:
tmuxPlugins.mkTmuxPlugin {
  pluginName = "smart-splits.nvim";
  version = "2.1.0";

  src = fetchFromGitHub {
    owner = "mrjones2014";
    repo = "smart-splits.nvim";
    rev = "v2.1.0";
    hash = "sha256-IuJNQT0bN68K5lnw0ixyU/heG8V1+zUwlvm0mNvvHOw=";
  };

  rtpFilePath = "smart-splits.tmux";

  meta = {
    homepage = "https://github.com/mrjones2014/smart-splits.nvim";
    description = "🧠 Smart, seamless, directional navigation and resizing of Neovim + terminal multiplexer splits. Supports Zellij, Tmux, Wezterm, and Kitty. Think about splits in terms of \"up/down/left/right\".";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
