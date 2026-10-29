{
  config,
  lib,
  pkgs,
  ...
}:
let
  skillMetadata = import ../../lib/skill-metadata.nix;

  baseSkills = import ../../../lib/ai-skills.nix {
    inherit lib;
    src = ../../../skills;
    metadata = skillMetadata;
  };

  assetSkills = import ../../../lib/ai-skills.nix {
    inherit lib;
    src = ../../../assets/skills;
    metadata = skillMetadata;
  };

  artifactsScript = ''
    #!/usr/bin/env bash
    exec ${pkgs.artifacts-helper}/bin/artifacts.sh "$@"
  '';

  scripted = [
    "init"
    "update"
    "retro"
    "brainstorm"
    "design"
    "specify"
    "plan"
    "implement"
    "review"
  ];

  scriptOverrides = lib.genAttrs scripted (name: {
    scripts."artifacts.sh" = artifactsScript;
  });
in
{
  ai.skills = baseSkills // lib.recursiveUpdate assetSkills scriptOverrides;

  assertions = [
    {
      assertion = lib.all (skill: skill.disableModelInvocation) (lib.attrValues config.ai.skills);
      message = "All ai.skills must set disableModelInvocation = true.";
    }
  ];
}
