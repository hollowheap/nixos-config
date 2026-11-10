{
  config,
  lib,
  pkgs,
  ...
}:
let
  aiRender = config.ai.render;
  cfg = config.programs.claude-code;

  systemPromptFile = pkgs.writeText "claude-system-prompt.md" cfg.systemPrompt;
  claudePackage = pkgs.writeShellScriptBin "claude" ''
    exec ${pkgs.claude-code}/bin/claude \
      ${if cfg.systemPromptMode == "replace" then "--system-prompt-file" else "--append-system-prompt-file"} \
      ${systemPromptFile} "$@"
  '';

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

      ${aiRender.agentBodyFor agent}
    '';

  mkSkill = aiRender.mkSkillDir {
    prefix = "claude-code";
    skills = config.ai.skills;
  };
in
{
  options.programs.claude-code = {
    systemPrompt = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "Follow the workspace instructions in AGENTS.md.";
      description = ''
        System prompt passed to Claude Code through --append-system-prompt-file.
        Set systemPromptMode to "replace" to pass --system-prompt-file instead.
        This is separate from context, which writes CLAUDE.md.
      '';
    };
    systemPromptMode = lib.mkOption {
      type = lib.types.enum [
        "append"
        "replace"
      ];
      default = "append";
      description = "Append the system prompt to Claude Code's built-in prompt or replace it.";
    };
  };

  config.programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    package = lib.mkIf (cfg.systemPrompt != "") claudePackage;

    context = aiRender.agentBodyFor config.ai.agents.engineer;

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
