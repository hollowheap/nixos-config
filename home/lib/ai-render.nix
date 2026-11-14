# Shared render helpers for the AI harness modules in modules/programs/.
#
# Every harness renderer translates the same harness-neutral `ai.*` schema into
# its own files. These helpers cover the parts that are identical across
# harnesses: capability-gated rule text, discipline blocks, markdown frontmatter,
# skill directories/file trees, and lifecycle hook formatting.
{ lib, pkgs }:
let
  inherit (lib)
    all
    concatStringsSep
    escapeShellArg
    filter
    mapAttrs
    mapAttrsToList
    optionalAttrs
    optionalString
    removeSuffix
    ;

  # Capability intersection used to decide which rules an agent receives.
  capabilityNames = [
    "read"
    "write"
    "execute"
    "delegate"
    "mcp"
    "web"
  ];

  defaultHookEvents = {
    session-start = "SessionStart";
    user-prompt = "UserPromptSubmit";
    pre-tool = "PreToolUse";
    post-tool = "PostToolUse";
    stop = "Stop";
    session-end = "SessionEnd";
    pre-compact = "PreCompact";
  };
in
rec {
  # Convert a kebab-case slug ("code-reviewer") into Title Case ("Code Reviewer").
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

  # Render YAML frontmatter + Markdown body document.
  mkMarkdownDoc =
    frontmatterAttrs: body:
    let
      yaml = removeSuffix "\n" (lib.generators.toYAML { } frontmatterAttrs);
    in
    ''
      ---
      ${yaml}
      ---

      ${body}
    '';

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

  # Resolve the effective tool matcher for a given harness.
  matcherFor =
    harness: hook:
    hook.matchers.${harness} or hook.matcher or null;

  # Hooks enabled for a harness. An empty harness list targets every renderer.
  hooksFor =
    harness: hooks:
    lib.filterAttrs (
      _: hook:
      hook.enabled
      && (hook.harnesses == [ ] || lib.elem harness hook.harnesses)
      && (hook.event != "post-tool" || (matcherFor harness hook) != null || hook.harnesses != [ ])
    ) hooks;

  # Render grouped hook specs used by Claude Code, Codex, and Antigravity.
  renderGroupedHooks =
    {
      harness,
      hooks,
      preToolFormat,
      eventMap ? defaultHookEvents,
      wrapNonToolEvents ? true,
    }:
    let
      mkEntry =
        _name: hook:
        let
          event = eventMap.${hook.event} or null;
          matcher = matcherFor harness hook;
          handler = {
            type = "command";
            command = "${hookCommandLine hook}${optionalString (hook.event == "pre-tool") " --format ${preToolFormat}"}";
            inherit (hook) timeout;
          };
          isToolEvent = event == "PreToolUse" || event == "PostToolUse";
        in
        if event == null then
          null
        else
          {
            inherit event;
            spec =
              if isToolEvent || wrapNonToolEvents then
                { hooks = [ handler ]; } // optionalAttrs (matcher != null) { inherit matcher; }
              else
                handler;
          };
      entries = filter (entry: entry != null) (mapAttrsToList mkEntry (hooksFor harness hooks));
    in
    mapAttrs (_event: evEntries: map (e: e.spec) evEntries) (
      builtins.groupBy (entry: entry.event) entries
    );

  # Render Kiro CLI hook list (`.kiro/hooks/ai-hooks.json`).
  renderKiroHooks =
    hooks:
    let
      kiroEvents = {
        session-start = "SessionStart";
        user-prompt = "UserPromptSubmit";
        pre-tool = "PreToolUse";
        post-tool = "PostToolUse";
        stop = "Stop";
      };
      mkHook =
        name: hook:
        let
          trigger = kiroEvents.${hook.event} or null;
          matcher = matcherFor "kiro" hook;
        in
        if trigger == null then
          null
        else
          {
            inherit name trigger;
            action = {
              type = "command";
              command = "${hookCommandLine hook}${optionalString (hook.event == "pre-tool") " --format stderr"}";
            };
            inherit (hook) timeout;
            enabled = true;
          }
          // optionalAttrs (matcher != null) { inherit matcher; };
    in
    filter (h: h != null) (mapAttrsToList mkHook (hooksFor "kiro" hooks));

  # Render OpenCode plugin hook manifest (`.config/opencode/ai-hooks.json`).
  renderOpencodeHooks =
    hooks:
    mapAttrs (
      _name: hook:
      let
        matcher = matcherFor "opencode" hook;
      in
      {
        command = "${hookCommandLine hook}${optionalString (hook.event == "pre-tool") " --format deny"}";
        inherit (hook) timeout;
      }
      // optionalAttrs (matcher != null) { inherit matcher; }
    ) (hooksFor "opencode" hooks);

  # Render Charm Crush `crushrc` hook commands (`PreToolUse` / `PostToolUse`).
  renderCrushRcHooks =
    hooks:
    let
      crushEvents = {
        pre-tool = "PreToolUse";
        post-tool = "PostToolUse";
      };
      mkLine =
        name: hook:
        let
          trigger = crushEvents.${hook.event} or null;
          matcher =
            let
              m = matcherFor "crush" hook;
            in
            if m != null then m else if hook.event == "pre-tool" then "^bash$" else null;
          cmd = "${hookCommandLine hook}${optionalString (hook.event == "pre-tool") " --format deny"}";
        in
        if trigger == null || matcher == null then
          null
        else
          ''
            hook add ${trigger} \
              --name ${escapeShellArg "ai-hooks-${name}"} \
              --matcher ${escapeShellArg matcher} \
              --command ${escapeShellArg cmd} \
              --timeout ${toString hook.timeout}
          '';
    in
    concatStringsSep "\n" (filter (l: l != null) (mapAttrsToList mkLine (hooksFor "crush" hooks)));

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
          description: ${builtins.toJSON (skill.description + descriptionSuffix name)}
          ${optionalString skill.disableModelInvocation "disable-model-invocation: true\n"}---

          ${content}
        ''
      } "$out/SKILL.md"
      ${concatStringsSep "\n" (mapAttrsToList (
        fileName: reference:
        if builtins.isAttrs reference then
          ''
            install -D -m0644 ${reference.source} "$out/references/${fileName}"
          ''
        else
          ''
            install -D -m0644 ${pkgs.writeText "${name}-reference-${fileName}" (renderSkill reference)} "$out/references/${fileName}"
          ''
      ) skill.references)}
      ${concatStringsSep "\n" (mapAttrsToList (fileName: content: ''
        install -m0755 ${pkgs.writeText "${name}-script-${fileName}" content} "$out/scripts/${fileName}"
      '') skill.scripts)}
    '';

  # Render `home.file` entries for harnesses that materialize skills as individual
  # files (`kiro-cli`, `pi-coding-agent`).
  mkSkillFileEntries =
    {
      baseDir,
      skills,
      invocation ? (name: name),
      includeDisableModelInvocation ? false,
    }:
    let
      renderSkill = renderSkillInvocation { inherit skills invocation; };
    in
    builtins.concatLists (
      mapAttrsToList (
        name: skill:
        [
          {
            name = "${baseDir}/${name}/SKILL.md";
            value.text = ''
              ---
              name: ${name}
              description: ${builtins.toJSON skill.description}
              ${optionalString (includeDisableModelInvocation && skill.disableModelInvocation) "disable-model-invocation: true\n"}---

              ${renderSkill skill.content}
            '';
          }
        ]
        ++ mapAttrsToList (
          fileName: content:
          if builtins.isAttrs content then
            {
              name = "${baseDir}/${name}/references/${fileName}";
              value.source = content.source;
            }
          else
            {
              name = "${baseDir}/${name}/references/${fileName}";
              value.text = renderSkill content;
            }
        ) skill.references
        ++ mapAttrsToList (fileName: content: {
          name = "${baseDir}/${name}/scripts/${fileName}";
          value = {
            text = content;
            executable = true;
          };
        }) skill.scripts
      ) skills
    );
}
