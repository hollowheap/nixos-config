{
  config,
  lib,
  pkgs,
  ...
}: let
  aiRender = config.ai.render;

  models = {
    architect = "opus";
    engineer = "opus";
    worker = "sonnet";
    scout = "haiku";
    researcher = "haiku";
    code-reviewer = "opus";
  };

  efforts = {
    architect = "xhigh";
    engineer = "high";
    worker = "high";
    scout = "max";
    researcher = "max";
    code-reviewer = "medium";
  };

  # Claude's built-in prompt covers untrusted pasted content, secrets privacy, native Read/Grep/Glob search tools,
  # dirty-worktree preservation, and native skill invocation rules.
  bodyFor = aiRender.agentBodyForWith {
    dropRules = ["security"];
    dropDisciplines = ["search"];
    dropDisciplineRules = {
      lazy = ["preserve"];
      skills = [
        "no-reload"
        "obey"
      ];
    };
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
      model = models.${name};
      effort = efforts.${name};
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
    mutableSettings = true;

    context = bodyFor config.ai.agents.engineer;

    settings = {
      theme = "custom:wallust";
      includeCoAuthoredBy = false;
      disableClaudeAiConnectors = true;
      autoCompactEnabled = true;
      verbose = true;
      editorMode = "normal";
      disableArtifact = true;
      outputStyle = "default";
      workflowKeywordTriggerEnabled = false;
      statusLine = {
        type = "command";
        command = "${pkgs.claude-statusline}/bin/claude-statusline";
        padding = 0;
      };
      permissions = {
        defaultMode = "auto";
        deny =
          (map (pattern: "Bash(${pattern})") config.ai.guards.bashDeny)
          ++ [
            "Agent(claude)"
            "Agent(claude-code-guide)"
            "Agent(statusline-setup)"
            "mcp__claude_ai_Claude_Docs"
          ]
          # Primary agents can be selected with `claude --agent <name>`, but the
          # model must not spawn them as subagents.
          ++ map (name: "Agent(${name})") (
            builtins.attrNames (
              lib.filterAttrs (_: agent: agent.role == "primary") config.ai.agents
            )
          );
      };
      hooks = claudeHooks;
      env = {
        CLAUDE_CODE_DISABLE_BUNDLED_SKILLS = "1";
        CLAUDE_CODE_DISABLE_EXPLORE_PLAN_AGENTS = "1";
        CLAUDE_CODE_DISABLE_POLICY_SKILLS = "1";
        CLAUDE_CODE_SUBAGENT_MODEL = models.worker;
        DISABLE_TELEMETRY = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_AUTOUPDATER = "1";
        ENABLE_CLAUDEAI_MCP_SERVERS = "false";
        CLAUDE_CODE_AUTO_COMPACT_WINDOW = toString config.ai.compaction.maxTokens;
      };
    };

    agents = builtins.mapAttrs mkAgent config.ai.agents;
    skills = builtins.mapAttrs mkSkill config.ai.skills;
    lspServers = config.toolchain.claudeLsp;
  };

  config.programs.wallust.settings.templates.claude-code = {
    template = "claude-code.json";
    target = "${config.programs.claude-code.configDir}/themes/wallust.json";
  };
}
