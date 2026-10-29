{ lib }:
let
  inherit (lib) hasPrefix removePrefix toLower;

  hexDigits = {
    "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4;
    "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
    "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
    "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
  };

  parseHexByte = s:
    let
      c1 = builtins.substring 0 1 s;
      c2 = builtins.substring 1 1 s;
    in
    if hexDigits ? ${c1} && hexDigits ? ${c2} then
      (hexDigits.${c1} * 16) + hexDigits.${c2}
    else
      128;

  isHexBright = hex:
    let
      raw = builtins.unsafeDiscardStringContext (removePrefix "#" (toString hex));
    in
    if builtins.stringLength raw >= 6 then
      let
        r = parseHexByte (builtins.substring 0 2 raw);
        g = parseHexByte (builtins.substring 2 2 raw);
        b = parseHexByte (builtins.substring 4 2 raw);
        luminance = (299 * r + 587 * g + 114 * b);
      in
      luminance >= 140250
    else
      false;

  brightNamedColors = [
    "yellow" "brightyellow" "bright-yellow"
    "cyan" "brightcyan" "bright-cyan"
    "green" "brightgreen" "bright-green"
    "white" "brightwhite" "bright-white"
  ];

  allNamedColors = brightNamedColors ++ [
    "black" "brightblack" "bright-black"
    "red" "brightred" "bright-red"
    "blue" "brightblue" "bright-blue"
    "magenta" "brightmagenta" "bright-magenta"
  ];

  brightAnsiSlots = [
    2 3 6 7 10 11 12 14 15
    "2" "3" "6" "7" "10" "11" "12" "14" "15"
  ];

  detectSimpleContrast = color:
    let
      s = builtins.unsafeDiscardStringContext (toString color);
      lower = toLower s;
    in
    if hasPrefix "#" s && builtins.stringLength s == 7 then
      if isHexBright s then "#000000" else "#ffffff"
    else if builtins.elem lower brightNamedColors then
      "black"
    else if builtins.elem color brightAnsiSlots then
      "black"
    else
      "white";

  detectContrast = color:
    let
      s = builtins.unsafeDiscardStringContext (toString color);
    in
    if hasPrefix "#{?" s then
      builtins.concatStringsSep "" (
        map (
          part:
          if builtins.isList part then
            builtins.head part
          else if
            builtins.elem (toLower part) allNamedColors
            || (hasPrefix "#" part && builtins.stringLength part == 7)
          then
            detectSimpleContrast part
          else
            part
        ) (builtins.split "([,}])" s)
      )
    else
      detectSimpleContrast color;
in
{
  inherit detectContrast detectSimpleContrast isHexBright;
}
