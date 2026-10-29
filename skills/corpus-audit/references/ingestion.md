# Corpus Ingestion Points

Read-only. Never mutate a session store. Redact secrets and tokens.

| Harness | Store | Query |
|---|---|---|
| OpenCode | `~/.local/share/opencode/opencode.db` | `sqlite3 DB "SELECT id, title, created_at FROM session ORDER BY created_at DESC LIMIT 20;"` |
| Pi | `~/.pi/agent/sessions/<project>/<timestamp>_<id>.jsonl` | `jq -r '.type' FILE` to map message, thinking, and tool lines |
| Codex | `~/.codex/state_5.sqlite` (`threads.rollout_path`) | `sqlite3 DB "SELECT id, title, datetime(created_at,'unixepoch') FROM threads ORDER BY created_at DESC LIMIT 20;"` |
| Kiro | `~/.kiro/sessions/*/sess_*/messages.jsonl`; index `~/.kiro/sessions/dashboard-search.db` | `sqlite3 DB "SELECT sid, title FROM sessions LIMIT 20;"` |
| Antigravity / Gemini | `~/.gemini/antigravity-cli/history.jsonl`; `conversation_summaries.db`; project `.system_generated/logs/transcript*.jsonl` | `sqlite3 DB "SELECT conversation_id, title, last_modified_time FROM conversation_summaries ORDER BY last_modified_time DESC LIMIT 20;"` |
| OMP | `~/.omp/agent/` has no local session store; UNVERIFIED | inspect after a session; do not invent a path |
| Crush | `~/.local/share/crush/projects.json`; no transcript store found; UNVERIFIED | inspect the JSON; do not assume history |
| Hermes | `~/.hermes/`; not installed; UNVERIFIED | check after first run |
| Copilot | `~/.copilot/` or `~/.config/github-copilot/`; not installed; UNVERIFIED | check after first run |

Use `nix run nixpkgs#sqlite -- DB "..."` when `sqlite3` is not on PATH. Cite session IDs per finding; never synthesize a transcript.
