{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  skillMetadata = import ../../lib/skill-metadata.nix;

  readSkills =
    src:
    import ../../../lib/ai-skills.nix {
      inherit lib;
      inherit src;
      metadata = skillMetadata;
    };

  opalSkills = readSkills (inputs.opal.outPath + "/skills");
  iridescentSkills = readSkills (inputs.iridescent + "/skills");
  docmdSkills = readSkills (inputs.docmd + "/skills");

  externalSkills = opalSkills // iridescentSkills // docmdSkills;

  externalNames = lib.concatMap lib.attrNames [
    opalSkills
    iridescentSkills
    docmdSkills
  ];

  duplicateExternal = builtins.attrNames (
    lib.filterAttrs (_: names: builtins.length names > 1) (builtins.groupBy (name: name) externalNames)
  );

  baseSkills = readSkills ../../../skills;

  assetSkills = readSkills ../../../assets/skills;

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
  ai.skills = lib.recursiveUpdate (externalSkills // baseSkills // assetSkills) scriptOverrides;

  assertions = [
    {
      assertion = lib.all (skill: skill.disableModelInvocation) (lib.attrValues config.ai.skills);
      message = "All ai.skills must set disableModelInvocation = true.";
    }
    {
      assertion = lib.all (skill: skill.content != "") (lib.attrValues config.ai.skills);
      message = "Every ai.skills entry must have non-empty content.";
    }
    {
      assertion = lib.all (
        name: config.ai.skills ? ${name}
      ) (lib.concatMap (agent: agent.skills) (lib.attrValues config.ai.agents));
      message = "Every skill listed by an agent must exist in ai.skills.";
    }
    {
      assertion = duplicateExternal == [ ];
      message = "External skill sources define duplicate names: ${builtins.concatStringsSep ", " duplicateExternal}.";
    }
  ];
}
