import { Plugin } from "@opencode/plugin";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const configDir = process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config");
const manifestPath = join(configDir, "opencode", "ai-hooks.json");

function loadHooks(): Record<string, { command: string; timeout: number }> {
  try {
    return JSON.parse(readFileSync(manifestPath, "utf8"));
  } catch {
    return {};
  }
}

const hooks = loadHooks();

function run(name: string, payload: unknown): string | null {
  const hook = hooks[name];
  if (!hook) return null;
  try {
    const output = execFileSync(hook.command, {
      shell: true,
      input: JSON.stringify(payload),
      encoding: "utf8",
      timeout: hook.timeout * 1000,
    });
    return output.trim() || null;
  } catch {
    return null;
  }
}

export default Plugin.define({
  id: "ai-hooks",
  async setup(ctx) {
    const controller = new AbortController();
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event.type === "session.created") {
          run("session-start", { event: event.type, cwd: ctx.location.directory });
        }
      }
    })().catch(() => {});

    await ctx.tool.hook("execute.before", (event) => {
      const result = run("pre-tool", {
        tool_name: event.tool,
        tool_input: event.input,
        cwd: ctx.location.directory,
      });
      if (!result) return;

      let decision: { decision?: string; reason?: string };
      try {
        decision = JSON.parse(result);
      } catch {
        return;
      }
      if (decision.decision === "deny") {
        throw new Error(decision.reason ?? "blocked by ai-hooks");
      }
    });

    return () => controller.abort();
  },
});
