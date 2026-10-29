{ ... }:
{
  desktop.windowRules = [
    {
      name = "thunderbird-popups";
      match.appId = "thunderbird";
      match.initialTitle = "(Write:.*|Address Book|Reminder)";
      float = true;
      opaque = true;
    }
  ];

  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
    };
  };
}
