{
  config,
  lib,
  ...
}: let
  aiRender = config.ai.render;

  # Claude's built-in prompt covers untrusted pasted content, secrets privacy, and parallel tool calls.
  bodyFor = aiRender.agentBodyForWith {
    dropRules = ["security"];
    dropDisciplineRules.search = ["batch"];
  };

  claudeTools = agent: let
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
    ++ lib.optionals caps.execute ["Bash"]
    ++ lib.optionals caps.web [
      "WebFetch"
      "WebSearch"
    ]
    ++ lib.optionals (caps.delegate && agent.role == "primary") ["Agent"];

  mkAgent = name: agent:
    aiRender.mkMarkdownDoc {
      inherit name;
      inherit (agent) description;
      tools = lib.concatStringsSep ", " (claudeTools agent);
      model = aiRender.modelFor "claude-code" agent;
      omitClaudeMd = true;
    } (bodyFor agent);

  mkSkill = aiRender.mkSkillDir {
    prefix = "claude-code";
    skills = config.ai.skills;
  };

  claudeHooks = aiRender.renderGroupedHooks {
    harness = "claude-code";
    hooks = config.ai.hooks;
    preToolFormat = "claude-json";
  };
in {
  config.programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    context = bodyFor config.ai.agents.engineer;

    settings = {
      theme = "custom:wallust";
      model = aiRender.tierModelFor "claude-code" "high";
      includeCoAuthoredBy = false;
      disableClaudeAiConnectors = true;
      permissions = {
        defaultMode = "auto";
        deny =
          (map (pattern: "Bash(${pattern})") config.ai.guards.bashDeny)
          ++ [
            "mcp__claude_ai_Claude_Docs"
          ];
      };
      hooks = claudeHooks;
      env = {
        DISABLE_TELEMETRY = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_AUTOUPDATER = "1";
        ENABLE_CLAUDEAI_MCP_SERVERS = "false";
      };
    };

    agents = builtins.mapAttrs mkAgent config.ai.agents;
    skills = builtins.mapAttrs mkSkill config.ai.skills;
  };

  config.programs.wallust.settings.templates.claude-code = {
    template = "claude-code.json";
    target = "${config.programs.claude-code.configDir}/themes/wallust.json";
  };
}
