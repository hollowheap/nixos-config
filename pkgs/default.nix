pkgs:
let
  inherit (pkgs) lib;

  # Convert kebab-case names to camelCase (e.g. hyprland-plugins -> hyprlandPlugins)
  kebabToCamel =
    str:
    let
      parts = lib.splitString "-" str;
      capitalize =
        w:
        if w == "" then
          ""
        else
          lib.toUpper (builtins.substring 0 1 w)
          + builtins.substring 1 (builtins.stringLength w) w;
    in
    if builtins.length parts <= 1 then
      str
    else
      lib.head parts + lib.concatMapStrings capitalize (lib.tail parts);

  # Recursively process directories into nested attrsets, and .nix files into packages
  processDir =
    scope: dir:
    let
      dirContents = builtins.readDir dir;

      validItems = lib.filterAttrs (
        name: type:
        name != "default.nix"
        && !lib.hasPrefix "." name
        && (
          type == "directory"
          || (type == "regular" && lib.hasSuffix ".nix" name)
          || (type == "symlink" && lib.hasSuffix ".nix" name)
        )
      ) dirContents;
    in
    lib.mapAttrs' (
      name: type:
      let
        itemPath = dir + "/${name}";
      in
      if type == "directory" then
        let
          attrName = kebabToCamel name;
          subScope = scope.${attrName} or { };
          mergedSubScope = if builtins.isAttrs subScope then subScope else { };
          subAttrSet = processDir mergedSubScope itemPath;
        in
        lib.nameValuePair attrName (mergedSubScope // subAttrSet)
      else
        let
          pkgName = lib.removeSuffix ".nix" name;
        in
        lib.nameValuePair pkgName (pkgs.callPackage itemPath { })
    ) validItems;
in
processDir pkgs ./.

