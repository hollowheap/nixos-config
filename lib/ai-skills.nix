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
      normalized = builtins.replaceStrings [ "\r\n" ] [ "\n" ] raw;
      lines = lib.splitString "\n" normalized;
      starts = lines != [ ] && head lines == "---";
      body = tail lines;
      end = lib.lists.findFirstIndex (line: line == "---") null body;
      unquote =
        value:
        let
          len = builtins.stringLength value;
          first = builtins.substring 0 1 value;
          last = builtins.substring (len - 1) 1 value;
        in
        if len >= 2 && first == "\"" && last == "\"" then
          builtins.replaceStrings [ "\\\"" ] [ "\"" ] (builtins.substring 1 (len - 2) value)
        else if len >= 2 && first == "'" && last == "'" then
          builtins.substring 1 (len - 2) value
        else
          value;
      trimLeft =
        line:
        let
          parts = match "[[:space:]]*(.*)" line;
        in
        elemAt parts 0;
      isIndented =
        line:
        line != ""
        && (builtins.substring 0 1 line == " " || builtins.substring 0 1 line == "\t");
      takeIndented =
        entries:
        if entries == [ ] then
          [ ]
        else if isIndented (head entries) then
          [ (head entries) ] ++ takeIndented (tail entries)
        else
          [ ];
      parseEntries =
        entries:
        if entries == [ ] then
          { }
        else
          let
            line = head entries;
            rest = tail entries;
            parts = match "([A-Za-z0-9_-]+):[[:space:]]*(.*)" line;
            block = if parts == null then null else match "(\\||>)([-+]?)" (elemAt parts 1);
            blockLines = map trimLeft (takeIndented rest);
            tailLines = lib.drop (builtins.length blockLines) rest;
          in
          if parts == null then
            parseEntries rest
          else
            let
              key = elemAt parts 0;
              inline = elemAt parts 1;
            in
            {
              ${key} =
                if block != null then
                  if elemAt block 0 == ">" then
                    concatStringsSep " " blockLines
                  else
                    concatStringsSep "\n" blockLines
                else if inline == "" then
                  concatStringsSep " " blockLines
                else
                  unquote inline;
            }
            // parseEntries (if block != null || inline == "" then tailLines else rest);
    in
    if !starts || end == null then
      {
        data = { };
        body = normalized;
      }
    else
      {
        data = parseEntries (lib.take end body);
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
              if
                lib.any (ext: lib.hasSuffix ".${ext}" (lib.toLower (toString file))) textExtensions
              then
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
