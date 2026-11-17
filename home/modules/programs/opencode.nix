{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList;

  aiRender = config.ai.render;

  toolsFor = capabilities: let
    caps = capabilities;
  in {
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

  modeFor = agent:
    if agent.role == "subagent"
    then "subagent"
    else if agent.mainAgent && agent.subagent
    then "all"
    else if agent.mainAgent
    then "primary"
    else "subagent";

  mkAgent = name: agent: let
    model = aiRender.modelFor "opencode" agent;
    effort = aiRender.effortFor "opencode" agent;
    tools =
      toolsFor agent.capabilities
      // {
        # Built-in question tool exists; gate it on the question skill like antigravity's ask_question.
        question = builtins.elem "question" agent.skills || builtins.elem "design" agent.skills;
        bash = agent.capabilities.execute || name == "architect";
      };
    deniedSkills =
      lib.filterAttrs (
        skillName: skill: !(builtins.elem name skill.agents || builtins.elem skillName agent.skills)
      )
      config.ai.skills;
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
    spawnableAgents =
      lib.filter (
        sub: (config.ai.agents.${sub} or {role = "primary";}).role == "subagent"
      )
      agent.availableAgents;
    taskPermSection = lib.concatStringsSep "\n" (
      [
        "  task:"
        "    \"*\": \"deny\""
      ]
      ++ map (sub: "    ${sub}: \"allow\"") spawnableAgents
    );
    scoutBashPermSection = lib.concatStringsSep "\n" (
      [
        "  bash:"
        "    \"*\": \"deny\""
      ]
      ++ map (pattern: "    ${builtins.toJSON pattern}: \"allow\"") config.ai.guards.scoutAllow
    );
    perms =
      if agent.role == "subagent"
      then
        if name == "scout" || name == "Scout"
        then ''
          permission:
          ${taskPermSection}
            skill: "deny"
          ${scoutBashPermSection}
        ''
        else if name == "worker"
        then ''
          permission:
          ${taskPermSection}
          ${bashPermSection}
          ${skillPermSection}
        ''
        else ''
          permission:
          ${taskPermSection}
            skill: "deny"
          ${bashPermSection}
        ''
      else if name == "architect"
      then ''
        permission:
        ${taskPermSection}
          edit:
            "*": "deny"
            ".artifacts/*.md": "allow"
          bash:
            "*": "deny"
            "artifacts*": "allow"
            "iridescent-artifacts*": "allow"
            "repomap*": "allow"
        ${skillPermSection}
      ''
      else ''
        permission:
        ${taskPermSection}
        ${bashPermSection}
        ${skillPermSection}
      '';
    toolsText = concatStringsSep "\n" (mapAttrsToList (tool: enabled: "  ${tool}: ${
        if enabled
        then "true"
        else "false"
      }")
      tools);
    effortLine = lib.optionalString (effort != null && !(lib.hasInfix "#" model)) "reasoningEffort: ${effort}\n";
  in ''
    ---
    description: ${builtins.toJSON agent.description}
    mode: ${modeFor agent}
    model: ${builtins.toJSON model}
    ${effortLine}tools:
    ${toolsText}
    ${perms}---

    ${aiRender.agentBodyFor agent}
  '';

  mkSkill = aiRender.mkSkillDir {
    prefix = "opencode";
    skills = config.ai.skills;
    invocation = name: "@${name}";
  };

  context = "";
in {
  programs.opencode = {
    enable = true;
    package = aiRender.wrapWithOpenCodeKey "opencode" pkgs.opencode;
    enableMcpIntegration = true;
    mutableSettings = false;
    settings = {
      "$schema" = "https://opencode.ai/config.json";
      model = config.ai.harnesses.opencode.agents.engineer.model;
      small_model = config.ai.harnesses.opencode.agents.scout.model;
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
      lsp = config.toolchain.opencodeLsp;
      formatter = config.toolchain.opencodeFormatters;
      compaction = {
        auto = true;
        buffer = config.ai.compaction.reserveTokens;
        keep.tokens = config.ai.compaction.keepRecentTokens;
      };
    };
    agents = mapAttrs mkAgent config.ai.agents;
    skills = mapAttrs mkSkill config.ai.skills;
    cli = {
      attention.notifications = true;
      session.sidebar = "hide";
      theme = {
        name = "wallust";
        mode = "system";
      };
      tabs = {
        indicators = "status";
        layout = "horizontal";
        scope = "cwd";
        mode = "off";
      };
    };
    inherit context;
  };

  programs.wallust.settings.templates.opencode = {
    template = "opencode.json";
    target = "${config.xdg.configHome}/opencode/themes/wallust.json";
  };

  home.file = {
    ".config/opencode/ai-hooks.json".text = builtins.toJSON (
      aiRender.renderOpencodeHooks config.ai.hooks
    );
    ".config/opencode/plugins/ai-hooks/index.ts".text = builtins.readFile ./opencode-ai-hooks.ts;
  };
}
