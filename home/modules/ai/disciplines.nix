{
  inputs,
  lib,
  ...
}: let
  iridescentRules = builtins.concatStringsSep "\n" (
    builtins.filter (l: l != "" && !(lib.hasPrefix "#" l)) (
      lib.splitString "\n" (builtins.readFile inputs.iridescent.lib.rulesFile)
    )
  );
in {
  ai.disciplines = {
    artifacts = {
      description = "Iridescent workspace artifact placement.";
      target = "primary";
      rules = {
        placement = iridescentRules;
      };
    };

    lazy = {
      description = "YAGNI and anti-overengineering.";
      target = "primary";
      rules = {
        yagni = "Satisfy immediate request with minimal diff; reject premature abstractions, helper functions, and speculative generalizations.";
        preserve = "Preserve existing working code and out-of-context dirty edits; avoid unsolicited refactoring. If unexpected changes appear in files you did not touch, stop and ask the user.";
        halt-on-pass = "Stop immediately once verification passes; never add post-pass polish, extra tests, or unrequested cleanup.";
        early-yield = "Verify codebase and docs first; never guess when unsure. Ask the user only for ambiguous intent, approach trade-offs, irreversible actions, or gaps unresolved after 2 failed commands or lookups.";
      };
    };

    search = {
      description = "Compact, bounded retrieval.";
      target = "primary";
      rules = {
        narrow = "Start from the narrowest known path; use `rg -n --smart-case` with a glob or file type. Never search `/` or `$HOME`.";
        batch = "Batch independent read and search calls in one turn instead of serializing one file per turn.";
        compact = "Return file:line plus the shortest decisive snippet; cap matches.";
        slice = "Use file-read offset/limit parameters to read only needed sections; never `cat` files in shell, re-read unchanged files, or re-read right after editing unless an external tool modified them.";
        stop = "Stop on the first decisive match; widen scope only after a miss.";
      };
    };

    unslop = {
      description = "High-density, fluff-free communication with safety break-glass.";
      target = "primary";
      rules = {
        density = "Answer first, then reason, then next step. Prioritize technical accuracy over agreement; flag flawed approaches directly. One idea per sentence, <=20 words. Keep negations, subjects, and articles explicit. No filler (just/really/basically/actually/simply). Code, paths, commands, numbers, errors stay verbatim.";
        break-glass = "Full sentences for: warnings, irreversible actions, order-sensitive steps, user repeats, persisted artifacts/code, status lines, and user questions.";
        tables = "Keep Markdown table cells short. Wrap long cells with `<br>` or move detail below the table; never force horizontal scrolling. Wrap paths and commands in backticks.";
        pre-send = "Pre-send check: delete announcement and recap sentences; verify negations and verbatim payloads; split ambiguous sentences.";
      };
    };

    report = {
      description = "End-of-turn output formula.";
      target = "primary";
      rules = {
        formula = ''
          End every turn with:
          Done: <changed files with :line>
          Verified: <command → result>
          Next|Blocked: <one line>
        '';
        review = "When asked for a code review, lead with severity-ordered findings (file:line), risks, and missing tests before any change summary.";
        verbatim = "Paths, commands, and results verbatim; no prose recap outside the formula. Standing user request defers unslop no-restate rule.";
      };
    };

    skills = {
      description = "Mandatory skill loading.";
      target = "primary";
      rules = {
        load = "Load a skill ONLY when its exact trigger condition is active in the current step; never preload skills speculatively.";
        no-reload = "Skills are loaded best-effort on demand; avoid reloading skills already absorbed into context.";
        obey = "Follow the skill's prescribed commands; never infer behavior from its description.";
      };
    };

    subagent-io = {
      description = "Subagent I/O contract and boundaries.";
      target = "subagent";
      rules = {
        telemetry = "Emit compact, self-contained fragments only (parent lacks your context): <path:line> — <symbol> — <note> (Scout) or <path:line>: [sev] <bug>. <fix>. (Reviewer). Keep code, commands, paths, and errors verbatim. Zero prose, greetings, or recaps. Report unverified gaps explicitly; never guess.";
        bounded = "Answer only the delegated query using offset/limit slice reads (30-60 lines), rg -n, fd, or nix eval; pipe long output through head, tail, or rg, never `cat`, re-read full files, dump large files, or run `strings`/`objdump`/`hexdump` on binaries, and stop once facts are collected.";
        read-only = "Subagents are strictly read-only; never mutate files, stage/commit, or expose secrets.";
      };
    };
  };
}
