{ ... }:
{
  desktop.windowRules = [
    {
      name = "discord-updater";
      match.appId = "discord";
      match.initialTitle = "Discord Updater";
      float = true;
    }
    {
      name = "discord-stream-popout";
      match.appId = "vesktop";
      match.initialTitle = "Discord Popout";
      float = true;
      center = true;
      size = [
        "monitor_w*0.6"
        "monitor_h*0.6"
      ];
    }
  ];

  programs.vesktop = {
    enable = true;
    vencord.settings = {
      enabledThemes = [ ];
      frameless = false;
      transparent = false;
      plugins = {
        AlwaysAnimated.enabled = true;
        Experimentals.enabled = false;
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
      audio = {
        workaround = false;
        onlySpeakers = true;
        ignoreVirtual = true;
      };
    };
  };
}
