{ ... }:

{
  desktop.touch = true;
  home-manager.sharedModules = [ { desktop.touch = true; } ];
}
