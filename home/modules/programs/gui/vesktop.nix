{ ... }:
{
  desktop.windowRules = [
    {
      name = "discord-updater";
      match.appId = "discord";
      match.initialTitle = "Discord Updater";
      float = true;
    }
  ];

  programs.vesktop = {
    enable = true;
    vencord.settings = {
      enabledThemes = [
        "noctalia.theme.css"
      ];
      frameless = true;
      transparent = true;
      plugins = {
        AlwaysAnimated.enabled = true;
        Experimentals.enabled = true;
        FakeNitro.enabled = true;
        FakeProfileThemes.enabled = true;
      };
    };

    settings = {
      discordBranch = "stable";
      minimizeToTray = true;
      arRpc = true;
      hardwareAcceleration = true;
      hardwareVideoAcceleration = true;
    };
  };
}
