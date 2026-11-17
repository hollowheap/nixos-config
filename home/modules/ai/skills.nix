{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  readSkills =
    src:
    import ../../../lib/ai-skills.nix {
      inherit lib;
      inherit src;
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
in
{
  home.packages = [
    inputs.iridescent.packages.${pkgs.stdenv.hostPlatform.system}.iridescent-artifacts
  ];

  ai.skills = externalSkills // baseSkills // assetSkills;

  assertions = [
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
