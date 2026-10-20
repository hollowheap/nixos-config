rec {
  # Recursively find all .nix files under dir, excluding default.nix
  scanModules =
    lib: dir:
    builtins.filter (f: lib.hasSuffix ".nix" f && baseNameOf f != "default.nix") (
      lib.filesystem.listFilesRecursive dir
    );

  # Helper to construct module default.nix imports
  mkModuleLoader =
    dir:
    { lib, ... }:
    {
      imports = scanModules lib dir;
    };
}
