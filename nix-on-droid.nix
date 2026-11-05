{ pkgs, ... }:

{
  system.stateVersion = "24.05";

  environment.packages = with pkgs; [
    fd
    git
    openssh
    ripgrep
  ];
}
