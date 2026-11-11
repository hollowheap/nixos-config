{
  config,
  lib,
  pkgs,
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
    ]
    ++ lib.optionals (caps.delegate && agent.role == "primary") [ "Agent" ];

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

  claudeHookEvent =
    event:
    {
      session-start = "SessionStart";
      user-prompt = "UserPromptSubmit";
      pre-tool = "PreToolUse";
      post-tool = "PostToolUse";
      stop = "Stop";
      session-end = "SessionEnd";
      pre-compact = "PreCompact";
    }.${event} or null;

  mkClaudeHook =
    name: hook:
    let
      event = claudeHookEvent hook.event;
      handler = {
        type = "command";
        command = "${aiRender.hookCommandLine hook}${lib.optionalString (hook.event == "pre-tool") " --format block"}";
        inherit (hook) timeout;
      };
    in
    if
      !hook.enabled
      || event == null
      || (hook.harnesses != [ ] && !(builtins.elem "claude-code" hook.harnesses))
    then
      null
    else
      {
        inherit event;
        spec =
          if event == "PreToolUse" || event == "PostToolUse" then
            { hooks = [ handler ]; } // lib.optionalAttrs (hook.matcher != null) { inherit (hook) matcher; }
          else
            { hooks = [ handler ]; };
      };

  claudeHookEntries = builtins.filter (entry: entry != null) (
    lib.mapAttrsToList mkClaudeHook config.ai.hooks
  );

  claudeHooks = builtins.mapAttrs (_event: entries: map (entry: entry.spec) entries) (
    builtins.groupBy (entry: entry.event) claudeHookEntries
  );
in
{
  config.programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    context = aiRender.agentBodyFor config.ai.agents.engineer;

    settings = {
      model = config.ai.tiers.high.models.claude-code or "opus";
      includeCoAuthoredBy = false;
      permissions.deny = map (pattern: "Bash(${pattern})") config.ai.guards.bashDeny;
      hooks = claudeHooks;
      env = {
        DISABLE_TELEMETRY = "1";
        DISABLE_ERROR_REPORTING = "1";
        DISABLE_AUTOUPDATER = "1";
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };
    };

    agents = builtins.mapAttrs mkAgent config.ai.agents;
    skills = builtins.mapAttrs mkSkill config.ai.skills;
  };
}
