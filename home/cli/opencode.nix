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
      perms =
        if agent.role == "subagent" then
          if name == "scout" || name == "Scout" then ''
permission:
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
  task:
    scout: "allow"
    researcher: "allow"
    code-reviewer: "allow"
    "*": "deny"
${bashPermSection}
${skillPermSection}
'' else ''
permission:
  skill: "deny"
${bashPermSection}
''
        else if name == "architect" then ''
permission:
  task:
${lib.concatStringsSep "\n" (map (sub: "    ${sub}: \"allow\"") agent.availableAgents)}
    "*": "deny"
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
  task:
    scout: "allow"
    "*": "deny"
${skillPermSection}
'' else ''
permission:
  task:
    general: "deny"
    explore: "deny"
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

  mkSkill = aiRender.mkSkillDir { prefix = "opencode"; };

  context = aiRender.context "opencode";
in
{
  programs.opencode = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "opencode-wrapped";
      paths = [ pkgs.opencode ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/opencode \
          --set-default OPENCODE_CONFIG "${config.xdg.configHome}/opencode/home-manager.json" \
          --set-default OPENCODE_TUI_CONFIG "${config.xdg.configHome}/opencode/home-manager-tui.json" \
          --unset OPENCODE_API_KEY
      '';
    };
    mutableSettings = true;
    settings = {
      "$schema" = "https://opencode.ai/config.json";
      model = opencodeModel;
      small_model = "opencode-go/beam-free";
      provider.opencode.env = [ ];
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
    tui.theme = "wallust";
    inherit context;
  };

  programs.wallust.settings.templates.opencode = {
    template = "opencode.json";
    target = "${config.home.homeDirectory}/.config/opencode/themes/wallust.json";
  };

  home.file = {
    ".config/opencode/ai-hooks.json".text = builtins.toJSON (
      builtins.mapAttrs (_name: hook: {
        command = "${hook.command} --harness opencode";
        inherit (hook) timeout;
      }) (
        lib.filterAttrs (
          _name: hook:
          hook.enabled && (hook.harnesses == [ ] || builtins.elem "opencode" hook.harnesses)
        ) config.ai.hooks
      )
    );
    ".config/opencode/plugins/ai-hooks.ts".text = builtins.readFile ./opencode-ai-hooks.ts;
  };
}
