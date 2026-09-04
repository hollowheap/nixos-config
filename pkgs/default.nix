pkgs:
let
  inherit (pkgs) lib;
  dirContents = builtins.readDir ./.;

  # 1. Filter: Keep directories AND .nix files (excluding default.nix)
  validItems = lib.filterAttrs (
    name: type:
    name != "default.nix"
    && (
      type == "directory"
      || (type == "regular" && lib.hasSuffix ".nix" name)
      || (type == "symlink" && lib.hasSuffix ".nix" name)
    )
  ) dirContents;

  # 2. Map: Use mapAttrs' to strip the ".nix" extension from the final attribute name
  packageMap = lib.mapAttrs' (
    name: _:
    let
      # If it's a file, drop the .nix. If it's a directory, keep the name as-is.
      pkgName = lib.removeSuffix ".nix" name;
    in
    # Return a name/value pair to construct the final attribute set
    lib.nameValuePair pkgName (pkgs.callPackage (./. + "/${name}") { })
  ) validItems;
in
packageMap
