#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if command -v python3 >/dev/null 2>&1; then
  exec python3 "$DIR/artifacts-helper.py" "$@"
fi

# Fallback to nix store python if available
NIX_PY="$(find /nix/store -maxdepth 3 -name "python3" -type f -perm -111 2>/dev/null | head -n 1 || true)"
if [ -n "$NIX_PY" ] && [ -x "$NIX_PY" ]; then
  exec "$NIX_PY" "$DIR/artifacts-helper.py" "$@"
fi

exec nix shell --inputs-from "$DIR/.." nixpkgs#python3 -c python3 "$DIR/artifacts-helper.py" "$@"
