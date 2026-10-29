{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mapAttrsToList optionals concatStringsSep optionalAttrs;

  aiRender = config.ai.render;
  renderSkill = aiRender.renderSkillInvocation { skills = config.ai.skills; };

  slugToTitle =
    slug:
    let
      words = lib.splitString "-" slug;
      capitalize =
        w:
        let
          len = builtins.stringLength w;
        in
        if len == 0 then
          ""
        else
          lib.toUpper (builtins.substring 0 1 w) + builtins.substring 1 (len - 1) w;
    in
    concatStringsSep " " (map capitalize words);

  mkSkillFiles =
    name: skill:
    [
      {
        name = ".kiro/skills/${name}/SKILL.md";
        value.text = ''
          # ${name}
          ${skill.description}

          ${renderSkill skill.content}
        '';
      }
    ]
    ++ (mapAttrsToList (refName: refContent: {
      name = ".kiro/skills/${name}/references/${refName}";
      value.text = renderSkill refContent;
    }) skill.references)
    ++ (mapAttrsToList (scriptName: scriptContent: {
      name = ".kiro/skills/${name}/scripts/${scriptName}";
      value = {
        text = scriptContent;
        executable = true;
      };
    }) skill.scripts);

  # Kiro built-ins are closed: no drops. Add rule names here once verified.
  droppedDisciplineRules = { };

  renderDiscipline = aiRender.renderDiscipline { dropped = droppedDisciplineRules; };

  mkDiscipline = name: d: {
    name = ".kiro/steering/${name}.md";
    value.text = renderDiscipline name d;
  };

  kiroToolsFor =
    agent:
    let
      caps = agent.capabilities;
      # Kiro subagent runtime lacks web_search, web_fetch, grep, and glob (silently ignored):
      # strip web for subagent-only agents instead of advertising tools that never fire.
      subagentOnly = !agent.mainAgent;
    in
    [ "read" ]
    ++ (optionals caps.write [ "write" ])
    ++ (optionals caps.execute [ "shell" ])
    ++ (optionals caps.delegate [ "subagent" ])
    ++ (optionals caps.mcp [ "@mcp" ])
    ++ (optionals (caps.web && !subagentOnly) [ "web" ]);

  kiroRulesFor =
    name: agent:
    let
      caps = agent.capabilities;
      writeRules =
        if name == "orchestrator" || name == "engineer" || name == "architect" then
          [ { capability = "fs_write"; match = [ "artifacts/tasks.md" "artifacts/specs.md" ]; effect = "allow"; } ]
        else
          [ { capability = "fs_write"; match = [ "artifacts/tasks.md" "artifacts/specs.md" ]; effect = "deny"; } ];
      noWriteRules = [ { capability = "fs_write"; match = [ "**" ]; effect = "deny"; } ];
      executeRules = [ { capability = "shell"; match = [ "**" ]; effect = "allow"; } ];
      delegateRules = optionals (agent.availableAgents != [ ]) [
        { capability = "subagent"; match = map slugToTitle agent.availableAgents; effect = "allow"; }
      ];
    in
    (if caps.write then writeRules else noWriteRules)
    ++ (optionals caps.execute executeRules)
    ++ (optionals caps.delegate delegateRules);

  kiroHookEvent =
    event:
    {
      session-start = "SessionStart";
      user-prompt = "UserPromptSubmit";
      pre-tool = "PreToolUse";
      post-tool = "PostToolUse";
      stop = "Stop";
    }.${event} or null;

  mkKiroHook =
    name: hook:
    let
      trigger = kiroHookEvent hook.event;
    in
    if
      !hook.enabled
      || trigger == null
      || (hook.harnesses != [ ] && !(builtins.elem "kiro" hook.harnesses))
    then
      null
    else
      {
        inherit name trigger;
        action = {
          type = "command";
          command = "${aiRender.hookCommandLine hook}${lib.optionalString (hook.event == "pre-tool") " --format stderr"}";
        };
        inherit (hook) timeout;
        enabled = true;
      }
      // optionalAttrs (hook.matcher != null) { inherit (hook) matcher; };

  preventOverwriteHook = pkgs.writeShellScript "prevent-overwrite.sh" ''
    PAYLOAD="$(cat)"
    CMD="$(echo "$PAYLOAD" | ${pkgs.jq}/bin/jq -r '.tool_input.command // empty')"
    PATH_VAL="$(echo "$PAYLOAD" | ${pkgs.jq}/bin/jq -r '.tool_input.file_path // .tool_input.path // empty')"
    if [ -n "$PATH_VAL" ] && [ -e "$PATH_VAL" ]; then
      echo "Overwriting existing files with create is denied by discipline. Use hunk editing instead." >&2
      exit 2
    fi
    exit 0
  '';

  kiroModelFor =
    tier:
    if tier == "high" then
      "claude-sonnet-5.5"
    else
      "claude-haiku-5.5";

  kiroEffortFor =
    tier:
    if tier == "high" then
      "low"
    else
      "xhigh";

  rulesText = aiRender.rulesText config.ai.rules;

  mkKiroAgent =
    name: agent:
    let
      caps = agent.capabilities;
      readOnly = !caps.write && !caps.execute;
      skillResources = map (s: "skill://.kiro/skills/${s}/SKILL.md") agent.skills;
      repomapResource = optionals readOnly [ "file://artifacts/repomap.md" ];
      rules = kiroRulesFor name agent;
      kiroModel = agent.models.kiro or (kiroModelFor agent.tier);
      kiroEffort = agent.models.kiroEffort or (kiroEffortFor agent.tier);
    in
    {
      name = ".kiro/agents/${name}.json";
      value.text = lib.generators.toJSON { } (
        {
          name = slugToTitle name;
          inherit (agent) description;
          prompt = agent.instructions + rulesText agent;
          tools = kiroToolsFor agent;
          resources = skillResources ++ repomapResource;
          includeMcpJson = caps.mcp;
          model = kiroModel;
          effort = kiroEffort;
        }
        // (lib.optionalAttrs (rules != [ ]) { permissions.rules = rules; })
      );
    };
in
{
  programs.kiro-cli = {
    enable = true;
    enableZshIntegration = true;
  };

  home.file = mkIf config.programs.kiro-cli.enable (
    builtins.listToAttrs (
      (builtins.concatLists (mapAttrsToList mkSkillFiles config.ai.skills))
      ++ (mapAttrsToList mkKiroAgent config.ai.agents)
      ++ (mapAttrsToList mkDiscipline config.ai.disciplines)
    )
    // {
      ".kiro/hooks/prevent-overwrite.json".text = lib.generators.toJSON { } {
        version = "v1";
        hooks = [
          {
            name = "prevent-overwrite";
            trigger = "PreToolUse";
            matcher = "fs_write|write";
            action = {
              type = "command";
              command = "${preventOverwriteHook}";
            };
            enabled = true;
          }
        ];
      };

      ".kiro/hooks/ai-hooks.json".text = lib.generators.toJSON { } {
        version = "v1";
        hooks = builtins.filter (hook: hook != null) (mapAttrsToList mkKiroHook config.ai.hooks);
      };
    }
  );
}
