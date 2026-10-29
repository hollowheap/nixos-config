{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrsToList optionalAttrs;

  aiRender = config.ai.render;
  renderSkill = aiRender.renderSkillInvocation {
    skills = config.ai.skills;
    invocation = name: "/skill:${name}";
  };

  # OMP prompt unverified for overlap: no drops.
  droppedDisciplineRules = { };

  renderDiscipline = aiRender.renderDiscipline { dropped = droppedDisciplineRules; };

  disciplines = concatStringsSep "\n\n" (mapAttrsToList renderDiscipline config.ai.disciplines);

  roster = concatStringsSep "\n" (
    mapAttrsToList (name: agent: "- ${name}: ${agent.description}") config.ai.agents
  );

  rulesText = aiRender.rulesText config.ai.rules;

  agentFiles = mapAttrsToList (name: agent: {
    name = ".omp/agent/agents/${name}.md";
    value.text = ''
      ---
      name: ${name}
      description: ${agent.description}
      model: ${aiRender.modelFor "omp" agent}
      effort: ${aiRender.effortFor "omp" agent}
      mode: ${if agent.capabilities.write then "ask" else "plan"}
      ---

      ${agent.instructions}${rulesText agent}
    '';
  }) config.ai.agents;

  skills = builtins.concatLists (
    mapAttrsToList (
      name: skill:
      [
        {
          name = ".omp/agent/skills/${name}/SKILL.md";
          value.text = ''
            ---
            name: ${name}
            description: ${skill.description}
            ${lib.optionalString skill.disableModelInvocation "disable-model-invocation: true\n"}---

            ${renderSkill skill.content}
          '';
        }
      ]
      ++ mapAttrsToList (fileName: content: {
        name = ".omp/agent/skills/${name}/references/${fileName}";
        value.text = renderSkill content;
      }) skill.references
      ++ mapAttrsToList (fileName: content: {
        name = ".omp/agent/skills/${name}/scripts/${fileName}";
        value = {
          text = content;
          executable = true;
        };
      }) skill.scripts
    ) config.ai.skills
  );

  hookFiles = [
    {
      name = ".omp/agent/hooks.json";
      value.text = builtins.toJSON {
        hooks =
          optionalAttrs (
            builtins.hasAttr "pre-tool" config.ai.hooks
            && config.ai.hooks.pre-tool.enabled
            && (
              config.ai.hooks.pre-tool.harnesses == [ ]
              || builtins.elem "omp" config.ai.hooks.pre-tool.harnesses
            )
          ) {
            preToolUse = [
              {
                matcher = if config.ai.hooks.pre-tool.matcher != null then config.ai.hooks.pre-tool.matcher else "bash";
                command = config.ai.hooks.pre-tool.command;
                args = config.ai.hooks.pre-tool.args ++ [
                  "--format"
                  "block"
                ];
                timeoutMs = config.ai.hooks.pre-tool.timeout * 1000;
              }
            ];
          }
          // lib.optionalAttrs (
            builtins.hasAttr "session-start" config.ai.hooks
            && config.ai.hooks.session-start.enabled
            && (
              config.ai.hooks.session-start.harnesses == [ ]
              || builtins.elem "omp" config.ai.hooks.session-start.harnesses
            )
          ) {
            sessionStart = [
              {
                command = config.ai.hooks.session-start.command;
                args = config.ai.hooks.session-start.args;
                timeoutMs = config.ai.hooks.session-start.timeout * 1000;
              }
            ];
          };
      };
    }
  ];

  authFile = [
    {
      name = ".omp/agent/auth.json";
      value = {
        force = true;
        text = builtins.toJSON {
          opencode = {
            type = "api_key";
            key = "!rbw get --folder dev/keys opencode";
          };
          opencode-go = {
            type = "api_key";
            key = "!rbw get --folder dev/keys opencode";
          };
        };
      };
    }
  ];

  systemFile = [
    {
      name = ".omp/agent/SYSTEM.md";
      value.text = ''
        # Available agents (full briefs in agents/*.md)

        ${roster}

        # Shared disciplines

        ${disciplines}
      '';
    }
  ];
in
{
  programs.omp = {
    enable = true;
    settings = {
      startup.quiet = true;
      theme.dark = "titanium";
      defaultThinkingLevel = aiRender.effortFor "omp" (config.ai.agents.engineer or { effort = "high"; });
    };
  };

  home.file = lib.mkIf config.programs.omp.enable (
    builtins.listToAttrs (
      hookFiles ++ skills ++ agentFiles ++ authFile ++ systemFile
    )
  );
}
