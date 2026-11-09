{
  pkgs,
  src,
}:
let
  inherit (pkgs) lib;

  skills = import (src + "/lib/ai-skills.nix") {
    inherit lib;
    src = src + "/tests/fixtures/skills";
  };

  summarize =
    skill:
    {
      inherit (skill) description content;
      inherit (skill) disableModelInvocation;
      references = builtins.mapAttrs (
        _: reference: if builtins.isAttrs reference then "binary" else reference
      ) skill.references;
      scripts = builtins.attrNames skill.scripts;
    };

  actual = builtins.mapAttrs (_: summarize) skills;

  expected = {
    binary = {
      description = "Binary fixture";
      content = "Body binary";
      disableModelInvocation = true;
      references = {
        "fixtures/sample.bin" = "binary";
        "note.md" = "note text\n";
      };
      scripts = [ ];
    };
    block = {
      description = "Folded line one folded line two";
      content = "Body block";
      disableModelInvocation = true;
      references = { };
      scripts = [ ];
    };
    continuation = {
      description = "continued one continued two";
      content = "Body continuation";
      disableModelInvocation = true;
      references = { };
      scripts = [ ];
    };
    disabled = {
      description = "Explicit opt-out";
      content = "Body disabled";
      disableModelInvocation = false;
      references = { };
      scripts = [ ];
    };
    literal = {
      description = "line one\nline two";
      content = "Body literal";
      disableModelInvocation = true;
      references = { };
      scripts = [ ];
    };
    plain = {
      description = "plain workspace skill";
      content = "# No frontmatter";
      disableModelInvocation = true;
      references = { };
      scripts = [ ];
    };
    quoted = {
      description = "UI craft: quoted";
      content = "Body quoted";
      disableModelInvocation = true;
      references = { };
      scripts = [ ];
    };
  };
in
pkgs.runCommand "check-skills" {
  nativeBuildInputs = [ pkgs.diffutils ];
  actualJson = pkgs.writeText "skills-actual.json" (builtins.toJSON actual);
  expectedJson = pkgs.writeText "skills-expected.json" (builtins.toJSON expected);
} ''
  diff -u "$expectedJson" "$actualJson"
  touch $out
''
