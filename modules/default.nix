{ lib, ... }:
let
  files = lib.filesystem.listFilesRecursive (builtins.path { path = ./.; name = "modules"; });
  nixFiles = builtins.filter (f: lib.hasSuffix ".nix" f && baseNameOf f != "default.nix") files;
in
{
  imports = nixFiles;
}
