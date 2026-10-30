{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      identityAgent = "/run/user/%i/rbw/ssh-agent-socket";
      serverAliveInterval = 60;
      controlMaster = "auto";
      controlPath = "~/.ssh/control-%C";
      controlPersist = "10m";
      hashKnownHosts = true;
    };
  };
}
