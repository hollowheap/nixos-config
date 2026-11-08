{
  lib,
  src,
  metadata ? { },
}:
let
  inherit (builtins)
    attrNames
    concatStringsSep
    elemAt
    filter
    head
    listToAttrs
    map
    match
    pathExists
    readDir
    readFile
    tail
    ;

  # Split portable frontmatter from a repo skill body. Harness metadata is
  # rendered by ai-render.nix, so the repo block must not survive to the output.
  splitFrontmatter =
    raw:
    let
      lines = lib.splitString "\n" raw;
      starts = lines != [ ] && head lines == "---";
      body = tail lines;
      end = lib.lists.findFirstIndex (line: line == "---") null body;
      parseLine =
        line:
        let
          parts = match "([A-Za-z0-9_-]+):[[:space:]]*(.*)" line;
        in
        if parts == null then
          null
        else
          {
            name = elemAt parts 0;
            value = elemAt parts 1;
          };
    in
    if !starts || end == null then
      {
        data = { };
        body = raw;
      }
    else
      {
        data = listToAttrs (filter (entry: entry != null) (map parseLine (lib.take end body)));
        body = concatStringsSep "\n" (lib.drop (end + 1) body);
      };

  skillNames = attrNames (
    lib.filterAttrs (_: type: type == "directory") (readDir src)
  );

  readTextFiles = dir:
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

  # Text references stay strings so renderers can substitute skill markers.
  # Binary fixtures (docx, pdf, images) keep their source path and are copied.
  textExtensions = [
    "md"
    "markdown"
    "txt"
    "json"
    "jsonc"
    "yaml"
    "yml"
    "toml"
    "sh"
    "bash"
    "py"
    "js"
    "mjs"
    "ts"
    "tsx"
    "css"
    "html"
    "xml"
    "svg"
    "csv"
    "ini"
    "conf"
    "nix"
    "rs"
    "go"
    "lua"
    "sql"
  ];

  readReferenceFiles = dir:
    if !(pathExists dir) then
      { }
    else
      listToAttrs (
        map
          (file: {
            name = builtins.unsafeDiscardStringContext (
              lib.removePrefix (toString dir + "/") (toString file)
            );
            value =
              if lib.any (ext: lib.hasSuffix ".${ext}" (toString file)) textExtensions then
                readFile file
              else
                { source = file; };
          })
          (lib.filesystem.listFilesRecursive dir)
      );

  readSkill = name:
    let
      dir = src + "/${name}";
      fm = splitFrontmatter (readFile (dir + "/SKILL.md"));
      meta = metadata.${name} or { };
    in
    {
      description = meta.description or fm.data.description or "${name} workspace skill";
      content = lib.trim fm.body;
      references = readReferenceFiles (dir + "/references");
      scripts = readTextFiles (dir + "/scripts");
      agents = meta.agents or [
        "engineer"
        "worker"
      ];
      disableModelInvocation =
        meta.disableModelInvocation or (fm.data."disable-model-invocation" or "true") == "true";
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
