import type { Plugin } from "@opencode-ai/plugin";
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const configDir = process.env.XDG_CONFIG_HOME ?? join(homedir(), ".config");
const manifestPath = join(configDir, "opencode", "ai-hooks.json");

type Hook = { command: string; timeout: number };

let manifestError: string | null = null;

function loadHooks(): Record<string, Hook> {
  try {
    return JSON.parse(readFileSync(manifestPath, "utf8")) as Record<string, Hook>;
  } catch (error) {
    manifestError = String(error);
    return {};
  }
}

const hooks = loadHooks();

const WRITE_TOOLS = new Set([
  "write",
  "edit",
  "patch",
  "apply_patch",
  "multi_edit",
  "write_file",
  "edit_file",
  "create_file",
]);

function run(name: string, payload: unknown): string | null {
  if (manifestError && name === "pre-tool") {
    throw new Error(`ai-hooks manifest is malformed: ${manifestError}`);
  }

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
  } catch (error) {
    if (name === "pre-tool") {
      throw new Error(`ai-hooks ${name} failed: ${String(error)}`);
    }
    return null;
  }
}

const plugin: Plugin = async ({ directory }) => ({
  event: async ({ event }) => {
    if (event.type === "session.created") {
      run("session-start", { event: event.type, cwd: directory });
    }
  },
  "tool.execute.before": async (input, output) => {
    const result = run("pre-tool", {
      tool_name: input.tool,
      tool_input: output.args,
      cwd: directory,
    });
    if (!result) return;

    let decision: { decision?: string; reason?: string };
    try {
      decision = JSON.parse(result);
    } catch {
      throw new Error("ai-hooks pre-tool returned malformed JSON");
    }
    if (decision.decision === "deny" || decision.decision === "block") {
      throw new Error(decision.reason ?? "blocked by ai-hooks");
    }
  },
  "tool.execute.after": async (input, output) => {
    if (!WRITE_TOOLS.has(input.tool)) return;
    run("post-tool", {
      tool_name: input.tool,
      tool_input: input.args,
      cwd: directory,
    });
  },
});

export default plugin;
