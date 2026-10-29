{ lib, src, metadata ? { } }:
let
  inherit (builtins)
    attrNames
    listToAttrs
    map
    pathExists
    readDir
    readFile
    ;

  skillNames = attrNames (
    lib.filterAttrs (_: type: type == "directory") (readDir src)
  );

  readFiles = dir:
    if !(pathExists dir) then
      { }
    else
      listToAttrs (
        map
          (file: {
            name = builtins.unsafeDiscardStringContext (baseNameOf (toString file));
            value = readFile file;
          })
          (lib.filesystem.listFilesRecursive dir)
      );

  readSkill = name:
    let
      dir = src + "/${name}";
      raw = readFile (dir + "/SKILL.md");
      meta = metadata.${name} or { };
    in
    {
      description = meta.description or "${name} workspace skill";
      content = lib.trim raw;
      references = readFiles (dir + "/references");
      scripts = readFiles (dir + "/scripts");
      agents = meta.agents or [
        "engineer"
        "worker"
      ];
      disableModelInvocation = meta.disableModelInvocation or true;
    };
in
listToAttrs (
  map
    (name: {
      inherit name;
      value = readSkill name;
    })
    skillNames
)
