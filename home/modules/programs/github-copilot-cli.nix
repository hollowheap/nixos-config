{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mapAttrs mapAttrsToList optionals concatStringsSep;

  aiRender = config.ai.render;

  copilotToolsFor =
    agent:
    let
      caps = agent.capabilities;
    in
    (optionals caps.read [ "read" "search" ])
    ++ (optionals caps.write [ "edit" ])
    ++ (optionals caps.execute [ "execute" ])
    ++ (optionals caps.delegate [ "agent" ])
    ++ (optionals caps.web [ "web" ])
    ++ (optionals (builtins.elem "plan" agent.skills) [ "todo" ]);

  mkAgent =
    _name: agent:
    # Copilot CLI currently exposes only `auto`; leave model and effort unset.
    let
      frontmatter = lib.generators.toYAML { } {
        inherit (agent) description;
        tools = copilotToolsFor agent;
      };
    in
    ''
      ---
      ${lib.removeSuffix "\n" frontmatter}
      ---

      ${aiRender.agentBodyFor "copilot" agent}
    '';

  mkSkill = aiRender.mkSkillDir {
    prefix = "copilot";
    skills = config.ai.skills;
  };

  # Copilot CLI built-ins are closed: no drops. Add rule names here once verified.
in
{
  programs.github-copilot-cli = {
    enable = true;
    mutableSettings = true;
    enableMcpIntegration = true;
    settings.autoUpdate = false;

    agents = mapAttrs mkAgent config.ai.agents;
    skills = mapAttrs mkSkill config.ai.skills;
  };
}
