{ ... }:

let
  traits = [
    "bluetooth"
    "cpu"
    "filesystems"
    "graphics"
    "hdr"
    "rgb"
    "touch"
    "wifi"
  ];
in
{
  imports = map (trait: ../../hardware/${trait}.nix) traits;
}
