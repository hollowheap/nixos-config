{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      serverAliveInterval = 60;
      controlMaster = "auto";
      controlPath = "~/.ssh/control-%C";
      controlPersist = "10m";
      hashKnownHosts = true;
    };
  };
}
