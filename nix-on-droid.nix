{ pkgs, ... }:

{
  system.stateVersion = "24.05";

  nix.extraOptions = "experimental-features = nix-command flakes";

  android-integration = {
    termux-setup-storage.enable = true;
    termux-wake-lock.enable = true;
    termux-wake-unlock.enable = true;
    termux-reload-settings.enable = true;
  };

  environment.packages = with pkgs; [
    fd
    git
    openssh
    ripgrep
  ];
}
