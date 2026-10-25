{ ... }:

{
  desktop.hdr = true;
  home-manager.sharedModules = [ { desktop.hdr = true; } ];
}
