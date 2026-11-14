# Harness Store Ingestion

Read-only. Never mutate a session store. Redact secrets and tokens. Use `nix run nixpkgs#sqlite -- DB "..."` when `sqlite3` is not on PATH. Cite session IDs per finding; never synthesize a transcript.

## Stores & Queries

- **OpenCode**
  - Store: `~/.local/share/opencode/opencode.db`
  - Query: `sqlite3 DB "SELECT id, title, created_at FROM session ORDER BY created_at DESC LIMIT 20;"`
- **Pi**
  - Store: `~/.pi/agent/sessions/<project>/<timestamp>_<id>.jsonl`
  - Query: `jq -r '.type' FILE` to map message, thinking, and tool lines
- **Codex**
  - Store: `~/.codex/state_5.sqlite` (`threads.rollout_path`)
  - Query: `sqlite3 DB "SELECT id, title, datetime(created_at,'unixepoch') FROM threads ORDER BY created_at DESC LIMIT 20;"`
- **Kiro**
  - Store: `~/.kiro/sessions/*/sess_*/messages.jsonl`; index `~/.kiro/sessions/dashboard-search.db`
  - Query: `sqlite3 DB "SELECT sid, title FROM sessions LIMIT 20;"`
- **Antigravity / Gemini**
  - Store: `~/.gemini/antigravity-cli/history.jsonl`; `conversation_summaries.db`; project `.system_generated/logs/transcript*.jsonl`
  - Query: `sqlite3 DB "SELECT conversation_id, title, last_modified_time FROM conversation_summaries ORDER BY last_modified_time DESC LIMIT 20;"`
- **Crush**
  - Store: `~/.local/share/crush/projects.json` (no transcript store found; UNVERIFIED)
  - Query: inspect the JSON; do not assume history
- **Hermes**
  - Store: `~/.hermes/` (not installed; UNVERIFIED; check after first run)
- **Copilot**
  - Store: `~/.copilot/` or `~/.config/github-copilot/` (not installed; UNVERIFIED; check after first run)
