{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList;

  aiRender = config.ai.render;

  toolsFor =
    capabilities:
    let
      caps = capabilities;
    in
    {
      read = caps.read;
      grep = caps.read;
      glob = caps.read;
      list = caps.read;
      edit = caps.write;
      write = caps.write;
      bash = caps.execute;
      task = caps.delegate;
      webfetch = caps.web;
    };

  opencodeModel = "opencode-go/deepseek-v4.1-flash";

  modeFor =
    agent:
    if agent.role == "subagent" then
      "subagent"
    else if agent.mainAgent && agent.subagent then
      "all"
    else if agent.mainAgent then
      "primary"
    else
      "subagent";

  mkAgent =
    name: agent:
    let
      rawModel = aiRender.modelFor "opencode" agent;
      model = if rawModel != null && rawModel != "" then rawModel else opencodeModel;
      effort = aiRender.effortFor "opencode" agent;
      tools = toolsFor agent.capabilities // {
        # Built-in question tool exists; gate it on the question skill like antigravity's ask_question.
        question = builtins.elem "question" agent.skills || builtins.elem "design" agent.skills;
        bash = agent.capabilities.execute || name == "architect";
      };
      deniedSkills = lib.filterAttrs (_skillName: skill: !(builtins.elem name skill.agents)) config.ai.skills;
      deniedSkillEntries = mapAttrsToList (skillName: _: "    ${skillName}: \"deny\"") deniedSkills;
      skillPermSection = lib.concatStringsSep "\n" (
        [
          "  skill:"
          "    \"*\": \"allow\""
        ]
        ++ deniedSkillEntries
      );
      bashPermSection = lib.concatStringsSep "\n" (
        [
          "  bash:"
          "    \"*\": \"allow\""
        ]
        ++ map (pattern: "    ${builtins.toJSON pattern}: \"deny\"") config.ai.guards.bashDeny
      );
      spawnableAgents = lib.filter (
        sub: (config.ai.agents.${sub} or { role = "primary"; }).role == "subagent"
      ) agent.availableAgents;
      taskPermSection = lib.concatStringsSep "\n" (
        [
          "  task:"
          "    \"*\": \"deny\""
        ]
        ++ map (sub: "    ${sub}: \"allow\"") spawnableAgents
      );
      perms =
        if agent.role == "subagent" then
          if name == "scout" || name == "Scout" then ''
permission:
${taskPermSection}
  skill: "deny"
  bash:
    "repomap*": "allow"
    "rg*": "allow"
    "fd*": "allow"
    "nix eval*": "allow"
    "nix flake show*": "allow"
    "git status*": "allow"
    "git log*": "allow"
    "git diff*": "allow"
    "*": "deny"
'' else if name == "worker" then ''
permission:
${taskPermSection}
${bashPermSection}
${skillPermSection}
'' else ''
permission:
${taskPermSection}
  skill: "deny"
${bashPermSection}
''
        else if name == "architect" then ''
permission:
${taskPermSection}
  edit:
    "artifacts/*.md": "allow"
    "*": "deny"
  write:
    "artifacts/*.md": "allow"
    "*": "deny"
  bash:
    "artifacts*": "allow"
    "repomap*": "allow"
    "*": "deny"
${skillPermSection}
'' else if name == "ask" then ''
permission:
${taskPermSection}
${skillPermSection}
'' else ''
permission:
${taskPermSection}
${bashPermSection}
${skillPermSection}
'';
      toolsText = concatStringsSep "\n" (mapAttrsToList (tool: enabled: "  ${tool}: ${if enabled then "true" else "false"}") tools);
      effortLine = lib.optionalString (effort != null && !(lib.hasInfix "#" model)) "reasoningEffort: ${effort}\n";
    in
    ''
      ---
      description: ${builtins.toJSON agent.description}
      mode: ${modeFor agent}
      model: ${builtins.toJSON model}
      ${effortLine}tools:
      ${toolsText}
      ${perms}---

      ${aiRender.agentBodyFor "opencode" agent}
    '';

  mkSkill = aiRender.mkSkillDir {
    prefix = "opencode";
    skills = config.ai.skills;
    invocation = name: "@${name}";
  };

  context = aiRender.context "opencode";
in
{
  programs.opencode = {
    enable = true;
    mutableSettings = false;
    settings = {
      "$schema" = "https://opencode.ai/config.json";
      model = opencodeModel;
      small_model = "opencode-go/beam-free";
      provider = {
        "opencode-go".env = [
          "OPENCODE_API_KEY"
          "OPENCODE_GO_API_KEY"
        ];
        opencode.env = [
          "OPENCODE_API_KEY"
        ];
      };
      agent.general.disable = true;
      agent.explore.disable = true;
      permission = {
        task = {
          general = "deny";
          explore = "deny";
        };
      };
    };
    agents = mapAttrs mkAgent config.ai.agents;
    skills = mapAttrs mkSkill config.ai.skills;
    cli = {
      attention.notifications = true;
      session.sidebar = "hide";
      theme.name = "system";
    };
    inherit context;
  };

  home.file = {
    ".config/opencode/ai-hooks.json".text = builtins.toJSON (
      builtins.mapAttrs (_name: hook: {
        command = "${aiRender.hookCommandLine hook}${lib.optionalString (hook.event == "pre-tool") " --format deny"}";
        inherit (hook) timeout;
      }) (
        lib.filterAttrs (
          _name: hook:
          hook.enabled && (hook.harnesses == [ ] || builtins.elem "opencode" hook.harnesses)
        ) config.ai.hooks
      )
    );
    ".config/opencode/plugins/ai-hooks/index.ts".text = builtins.readFile ./opencode-ai-hooks.ts;
  };
}
