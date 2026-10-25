{ pkgs, src }:
let
  inherit (pkgs) lib;

  testFiles = builtins.filter (
    file: lib.hasSuffix ".nix" file && baseNameOf file != "default.nix"
  ) (lib.filesystem.listFilesRecursive ./.);
in
builtins.listToAttrs (
  map (
    file:
    let
      name = lib.removeSuffix ".nix" (baseNameOf file);
    in
    lib.nameValuePair name (import file { inherit pkgs src; })
  ) testFiles
)
