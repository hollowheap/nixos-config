{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mapAttrsToList optionals optionalAttrs;

  aiRender = config.ai.render;
  inherit (aiRender) slugToTitle;

  models = {
    architect = "claude-opus-5.5";
    engineer = "claude-haiku-5.5";
    worker = "claude-sonnet-5.5";
    scout = "claude-haiku-5.5";
    researcher = "claude-haiku-5.5";
    code-reviewer = "claude-haiku-5.5";
  };
  scoutShell = config.ai.guards.scoutAllow;

  # Kiro built-ins are closed: no drops. Add rule names here once verified.
  kiroToolsFor =
    agent:
    let
      caps = agent.capabilities;
    in
    [ "read" ]
    ++ (optionals caps.write [ "write" ])
    ++ (optionals caps.execute [ "shell" ])
    ++ (optionals caps.delegate [ "subagent" ])
    ++ (optionals caps.mcp [ "@mcp" ])
    ++ (optionals caps.web [ "web" ]);

  kiroRulesFor =
    name: agent:
    let
      caps = agent.capabilities;
      writeRules =
        if name == "architect" then
          [
            {
              capability = "fs_write";
              match = [ "**" ];
              exclude = [ ".artifacts/*.md" ];
              effect = "deny";
            }
            {
              capability = "fs_write";
              match = [ ".artifacts/*.md" ];
              effect = "allow";
            }
          ]
        else if caps.write then
          [
            {
              capability = "fs_write";
              match = [ "**" ];
              effect = "allow";
            }
          ]
        else
          [
            {
              capability = "fs_write";
              match = [ "**" ];
              effect = "deny";
            }
          ];
      executeRules =
        if name == "scout" then
          [
            {
              capability = "shell";
              match = [ "**" ];
              exclude = scoutShell;
              effect = "deny";
            }
          ]
          ++ map (pattern: {
            capability = "shell";
            match = [ pattern ];
            effect = "allow";
          }) scoutShell
        else
          [ { capability = "shell"; match = [ "**" ]; effect = "allow"; } ]
          ++ optionals caps.execute (
            map (pattern: {
              capability = "shell";
              match = [ pattern ];
              effect = "deny";
            }) config.ai.guards.bashDeny
          );
      delegateRules = optionals (agent.availableAgents != [ ]) [
        { capability = "subagent"; match = map slugToTitle agent.availableAgents; effect = "allow"; }
      ];
    in
    writeRules ++ (optionals caps.execute executeRules) ++ (optionals caps.delegate delegateRules);

  preventOverwriteHook = pkgs.writeShellScript "prevent-overwrite.sh" ''
    set -euo pipefail
    PAYLOAD="$(cat)"
    PATH_VAL="$(printf '%s' "$PAYLOAD" | ${pkgs.jq}/bin/jq -r '.tool_input.file_path // .tool_input.path // empty')"
    if [ -n "$PATH_VAL" ] && [ -e "$PATH_VAL" ]; then
      echo "Overwriting existing files with create is denied by discipline. Use hunk editing instead." >&2
      exit 2
    fi
    exit 0
  '';

  mkKiroAgent =
    name: agent:
    let
      caps = agent.capabilities;
      skillResources = map (s: "skill://.kiro/skills/${s}/SKILL.md") agent.skills;
      rules = kiroRulesFor name agent;
      kiroModel = models.${name};
    in
    {
      name = ".kiro/agents/${name}.json";
      value.text = lib.generators.toJSON { } (
        {
          name = slugToTitle name;
          inherit (agent) description;
          prompt = aiRender.agentBodyFor agent;
          tools = kiroToolsFor agent;
          resources = skillResources;
          includeMcpJson = caps.mcp;
          model = kiroModel;
        }
        // (optionalAttrs (rules != [ ]) { permissions.rules = rules; })
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
      (aiRender.mkSkillFileEntries {
        baseDir = ".kiro/skills";
        skills = config.ai.skills;
      })
      ++ (mapAttrsToList mkKiroAgent config.ai.agents)
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
        hooks = aiRender.renderKiroHooks {
          hooks = config.ai.hooks;
          # Native permission rules deny the same git policy patterns.
          dropHooks = [ "pre-tool" ];
        };
      };
    }
  );
}
