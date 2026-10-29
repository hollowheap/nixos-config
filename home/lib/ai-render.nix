# Shared render helpers for the AI harness modules in modules/programs/.
#
# Every harness renderer translates the same harness-neutral `ai.*` schema into
# its own files. These helpers cover the parts that are identical across
# harnesses: capability-gated rule text, discipline blocks, skill directories,
# and the zen-provider model tier map. Harness specifics (tool vocabularies,
# model ids, permission rules, and drop lists) stay in the renderer that owns
# them.
{ lib, pkgs }:
let
  inherit (lib) all concatStringsSep escapeShellArg filter filterAttrs mapAttrsToList optionalString;

  # Capability intersection used to decide which rules an agent receives.
  capabilityNames = [
    "read"
    "write"
    "execute"
    "delegate"
    "mcp"
    "web"
  ];
in
rec {
  # Rules whose required capabilities the agent holds, rendered as prompt text.
  rulesText =
    rules: agent:
    let
      matches = rule: all (cap: !rule.requires.${cap} || agent.capabilities.${cap}) capabilityNames;
      kept = filter matches rules;
    in
    optionalString (kept != [ ]) ("\n\n" + concatStringsSep "\n\n" (map (rule: rule.text) kept));

  # Render a hook command plus its argument list as one shell command line.
  hookCommandLine =
    hook:
    concatStringsSep " " ([ hook.command ] ++ map escapeShellArg hook.args);

  # A global discipline block. `dropped` lists rule names the harness's built-in
  # prompt already covers; `heading` and `separator` let a harness match its own
  # layout (e.g. crush nests under "##", copilot joins with single newlines).
  renderDiscipline =
    {
      dropped ? { },
      heading ? "#",
      separator ? "\n\n",
    }:
    name: discipline:
    let
      drop = dropped.${name} or [ ];
      kept = filterAttrs (rule: text: text != null && !(builtins.elem rule drop)) discipline.rules;
    in
    ''
      ${heading} ${name}
      ${discipline.description}

      ${concatStringsSep separator (mapAttrsToList (_: text: text) kept)}
    '';

  # Replace `{{skill:name}}` markers with the harness's invocation syntax.
  renderSkillInvocation =
    {
      skills,
      invocation ? (name: name),
    }:
    content:
    lib.foldl' (
      text: skillName:
      builtins.replaceStrings
        [ "{{skill:${skillName}}}" ]
        [ (invocation skillName) ]
        text
    ) content (builtins.attrNames skills);

  # A skill directory derivation: SKILL.md plus optional references/ and
  # scripts/. `descriptionSuffix` appends harness-specific activation guidance
  # to the frontmatter description.
  mkSkillDir =
    {
      prefix,
      skills ? { },
      invocation ? (name: name),
      descriptionSuffix ? (_: ""),
    }:
    name: skill:
    let
      renderSkill = renderSkillInvocation { inherit skills invocation; };
      content = renderSkill skill.content;
    in
    pkgs.runCommandLocal "${prefix}-skill-${name}" { } ''
      mkdir -p "$out/references" "$out/scripts"
      cp ${
        pkgs.writeText "${name}-SKILL.md" ''
          ---
          name: ${name}
          description: ${skill.description}${descriptionSuffix name}
          ${optionalString skill.disableModelInvocation "disable-model-invocation: true\n"}---

          ${content}
        ''
      } "$out/SKILL.md"
      ${concatStringsSep "\n" (mapAttrsToList (fileName: reference: ''
        cp ${pkgs.writeText "${name}-reference-${fileName}" (renderSkill reference)} "$out/references/${fileName}"
      '') skill.references)}
      ${concatStringsSep "\n" (mapAttrsToList (fileName: content: ''
        install -m0755 ${pkgs.writeText "${name}-script-${fileName}" content} "$out/scripts/${fileName}"
      '') skill.scripts)}
    '';

  # Shared model tier -> OpenCode Go model id map. `prefix` is kept for
  # harnesses that need a different provider-qualified form.
  opencodeGoModelFor =
    { prefix ? "" }:
    model:
    if model == "low" then
      "${prefix}opencode-go/beam-free"
    else if model == "medium" || model == "high" then
      "${prefix}opencode-go/deepseek-v4.1-flash"
    else
      model;
}
