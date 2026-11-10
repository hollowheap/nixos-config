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

  configDir = config.programs.pi-coding-agent.configDir;

  roster = concatStringsSep "\n" (
    mapAttrsToList (name: agent: "- ${name}: ${agent.description}") config.ai.agents
  );

  agentFiles = mapAttrsToList (name: agent: {
    name = "${configDir}/agents/${name}.md";
    value.text = ''
      ---
      name: ${name}
      description: ${builtins.toJSON agent.description}
      model: ${aiRender.modelFor "pi" agent}
      effort: ${aiRender.effortFor "pi" agent}
      mode: ${if agent.capabilities.write then "ask" else "plan"}
      ---

      ${aiRender.agentBodyFor "pi" agent}
    '';
  }) config.ai.agents;

  dashboardFile = [
    {
      name = "${configDir}/dashboard.json";
      value.text = builtins.toJSON {
        width = 80;
        sections = [
          {
            type = "terminal";
            command = "${pkgs.hollowpi-colorscript}/bin/hollowpi-colorscript";
            args = [ ];
            intervalMs = 3600000;
            align = "center";
            gap = 1;
          }
        ];
      };
    }
  ];

  statuslineContent = builtins.toJSON {
    extensions = [
      "mode-guard"
      "usage"
    ];
    options = {
      componentSeparator = " ";
      sectionSeparator = "  ";
      gitIntervalMs = 5000;
    };
    sections = {
      a = [
        (config.styles.pills.pi.mode {
          type = "mode-guard";
          accent = "bright-yellow";
        })
      ];
      b = [
        (config.styles.pills.pi.left {
          icon = "";
          component = {
            type = "git_branch";
          };
          accent = "bright-cyan";
          bold = false;
        })
      ];
      c = [
        (config.styles.pills.pi.left {
          icon = "󱈸";
          component = {
            type = "git_diff";
            addedIcon = "+";
            modifiedIcon = "~";
            removedIcon = "-";
            untrackedIcon = "?";
          };
          accent = "bright-yellow";
          bold = false;
        })
      ];
      d = [
        (config.styles.pills.pi.left {
          icon = "";
          component = {
            type = "cwd";
            depth = 3;
            homeAsTilde = true;
          };
          accent = "bright-blue";
          bold = false;
        })
      ];
      w = [
        (config.styles.pills.pi.right {
          icon = "󰚩";
          component = {
            type = "model";
            shorten = true;
          };
          accent = "bright-purple";
          bold = false;
        })
      ];
      x = [
        (config.styles.pills.pi.right {
          icon = "󰧑";
          component = {
            type = "thinking";
          };
          accent = "bright-green";
          bold = false;
        })
      ];
      y = [
        (config.styles.pills.pi.right {
          icon = "󰕲";
          component = {
            type = "tokens";
            showInput = true;
            showOutput = true;
          };
          accent = "bright-blue";
          bold = false;
        })
        (config.styles.pills.pi.right {
          icon = "󰍛";
          component = {
            type = "context";
          };
          accent = "bright-green";
          bold = false;
        })
        (config.styles.pills.pi.right {
          icon = "󰃖";
          component = {
            type = "cost";
            decimals = 3;
          };
          accent = "bright-green";
          bold = false;
        })
        (config.styles.pills.pi.right {
          icon = "󰇁";
          component = {
            type = "usage";
          };
          accent = "bright-yellow";
          bold = false;
        })
      ];
      z = [
        (config.styles.pills.pi.right {
          icon = "󱑂";
          component = {
            type = "clock";
            format = "HH:mm";
          };
          accent = "bright-magenta";
          bold = false;
        })
      ];
    };
  };

  statuslineFile = [
    {
      name = "${configDir}/statusline.json";
      value.text = statuslineContent;
    }
    {
      name = "${configDir}/pi-statusline.json";
      value.text = statuslineContent;
    }
  ];

  skills = builtins.concatLists (
    mapAttrsToList (
      name: skill:
      [
        {
          name = "${configDir}/skills/${name}/SKILL.md";
          value.text = ''
            ---
            name: ${name}
            description: ${builtins.toJSON skill.description}
            ${lib.optionalString skill.disableModelInvocation "disable-model-invocation: true\n"}---

            ${renderSkill skill.content}
          '';
        }
      ]
      ++ mapAttrsToList (
        fileName: content:
        if builtins.isAttrs content then
          {
            name = "${configDir}/skills/${name}/references/${fileName}";
            value.source = content.source;
          }
        else
          {
            name = "${configDir}/skills/${name}/references/${fileName}";
            value.text = renderSkill content;
          }
      ) skill.references
      ++ mapAttrsToList (fileName: content: {
        name = "${configDir}/skills/${name}/scripts/${fileName}";
        value = {
          text = content;
          executable = true;
        };
      }) skill.scripts
    ) config.ai.skills
  );

  authFile = [
    {
      name = "${configDir}/auth.json";
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

  # pi-memory observer uses the low tier: opencode-go/beam-free, the cheapest
  # 64k+ route. Resolved through ai.tiers, not a separate model map.
  memoryFile = [
    {
      name = "${configDir}/memory.json";
      value = {
        force = true;
        text = builtins.toJSON {
          enabled = true;
          model = "${config.ai.tiers.low.provider}/${config.ai.tiers.low.model}";
          observeAfterTokens = 20000;
          maxObservations = 40;
          injectionTokens = 2000;
          redactSecrets = true;
          notifyErrors = true;
        };
      };
    }
  ];

  piWrapper = pkgs.writeShellScriptBin "pi" ''
    if [ -z "$OPENCODE_API_KEY" ] && command -v ${pkgs.rbw}/bin/rbw >/dev/null && ${pkgs.rbw}/bin/rbw unlocked >/dev/null 2>&1; then
      _k="$(${pkgs.rbw}/bin/rbw get --folder dev/keys opencode 2>/dev/null || true)"
      if [ -n "$_k" ]; then
        export OPENCODE_API_KEY="$_k"
        export OPENCODE_GO_API_KEY="$_k"
      fi
      unset _k
    fi
    exec ${pkgs.pi-coding-agent}/bin/pi "$@"
  '';
in
{
  programs.pi-coding-agent = {
    enable = true;
    package = piWrapper;
    extraPackages = [
      pkgs.git
      pkgs.nodejs
    ];
    settings = {
      enableInstallTelemetry = false;
      defaultTools = [ "+codemode" ];
      defaultThinkingLevel = aiRender.effortFor "pi" (config.ai.agents.engineer or { effort = "high"; });
      packages = [
        "git:github.com/hollowheap/pi-extensions@main"
      ];
      extensions = [
        "-builtin:tool-search"
        "-builtin:mcp"
        "-builtin:llama.cpp"
      ];
    };
    context = ''
      # Available agents (full briefs in agents/*.md)

      ${roster}
    '';
  };

  home.file = lib.mkIf config.programs.pi-coding-agent.enable (
    builtins.listToAttrs (
      skills ++ agentFiles ++ dashboardFile ++ statuslineFile ++ authFile ++ memoryFile
    )
  );
}
