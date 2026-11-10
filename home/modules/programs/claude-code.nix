{
  config,
  lib,
  ...
}:
let
  aiRender = config.ai.render;

  claudeTools =
    agent:
    let
      caps = agent.capabilities;
    in
    lib.optionals caps.read [
      "Read"
      "Grep"
      "Glob"
    ]
    ++ lib.optionals caps.write [
      "Edit"
      "Write"
    ]
    ++ lib.optionals caps.execute [ "Bash" ]
    ++ lib.optionals caps.web [
      "WebFetch"
      "WebSearch"
    ];

  subagents = lib.filterAttrs (_: agent: agent.role == "subagent") config.ai.agents;

  mkAgent =
    name: agent:
    let
      tools = claudeTools agent;
      frontmatter = lib.generators.toYAML { } {
        inherit name;
        description = agent.description;
        tools = lib.concatStringsSep ", " tools;
        model = aiRender.modelFor "claude-code" agent;
      };
    in
    ''
      ---
      ${lib.removeSuffix "\n" frontmatter}
      ---

      ${aiRender.agentBodyFor "claude-code" agent}
    '';

  mkSkill = aiRender.mkSkillDir {
    prefix = "claude-code";
    skills = config.ai.skills;
  };
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    context = aiRender.agentBodyFor "claude-code" config.ai.agents.engineer;

    settings = {
      model = config.ai.tiers.high.models.claude-code or "opus";
      includeCoAuthoredBy = false;
      permissions.deny = map (pattern: "Bash(${pattern})") config.ai.guards.bashDeny;
      env = {
        DISABLE_TELEMETRY = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_AUTOUPDATER = "1";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };
    };

    agents = builtins.mapAttrs mkAgent subagents;
    skills = builtins.mapAttrs mkSkill config.ai.skills;
  };
}
