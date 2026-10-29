{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) concatStringsSep mapAttrs mapAttrsToList optionalAttrs;

  aiRender = config.ai.render;

  # No nix package for Hermes Agent (curl installer only, MIT, NousResearch/hermes-agent):
  # install the binary upstream, then `hermes import-agent` can bootstrap from the
  # managed Codex setup. This module manages skills + config declaratively.
  # Hermes scans external skill dirs alongside ~/.hermes/skills, keeping managed
  # skills separate from agent-created ones.
  mkSkillDir = aiRender.mkSkillDir {
    prefix = "hermes";
    skills = config.ai.skills;
  };

  skillDrvs = mapAttrs mkSkillDir config.ai.skills;

  skillsRoot = pkgs.runCommandLocal "hermes-skills" { } (
    ''
      mkdir -p "$out"
    ''
    + concatStringsSep "\n" (
      mapAttrsToList (name: _: ''
        ln -s ${skillDrvs.${name}} "$out/${name}"
      '') config.ai.skills
    )
  );

in
{
  home.file.".hermes/config.yaml".text = lib.generators.toYAML { } {
    skills = {
      external_dirs = [ "${skillsRoot}" ];
    };
    hooks =
      optionalAttrs (
        builtins.hasAttr "pre-tool" config.ai.hooks
        && config.ai.hooks.pre-tool.enabled
        && (
          config.ai.hooks.pre-tool.harnesses == [ ]
          || builtins.elem "hermes" config.ai.hooks.pre-tool.harnesses
        )
      ) {
        pre_tool_call = [
          (
            {
              command = "${aiRender.hookCommandLine config.ai.hooks.pre-tool} --format block";
              inherit (config.ai.hooks.pre-tool) timeout;
            }
            // lib.optionalAttrs (config.ai.hooks.pre-tool.matcher != null) {
              inherit (config.ai.hooks.pre-tool) matcher;
            }
          )
        ];
      }
      // optionalAttrs (
        builtins.hasAttr "session-start" config.ai.hooks
        && config.ai.hooks.session-start.enabled
        && (
          config.ai.hooks.session-start.harnesses == [ ]
          || builtins.elem "hermes" config.ai.hooks.session-start.harnesses
        )
      ) {
        on_session_start = [
          {
            command = aiRender.hookCommandLine config.ai.hooks.session-start;
            inherit (config.ai.hooks.session-start) timeout;
          }
        ];
      };
    hooks_auto_accept = true;
  };
}
