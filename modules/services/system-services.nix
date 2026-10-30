{ config, ... }:
{
  services = {
    xserver.enable = false;
    openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        AllowUsers = [ "hollowheap" ];
      };
    };
    fwupd.enable = true;
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];
}