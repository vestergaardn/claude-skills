#!/usr/bin/env bash
# Installs the personal Claude Code setup into a Conductor cloud workspace.
#
# A repo-level scripts.setup REPLACES the user-level one, so every repo that
# defines its own setup must call this too, not only ~/.conductor/settings.toml.
# Never exit non-zero: a failure here must not fail workspace creation.
set -uo pipefail

[ "${CONDUCTOR_IS_LOCAL:-0}" = "1" ] && exit 0

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR/skills"

cp -R "$SRC/skills/." "$CLAUDE_DIR/skills/" 2>/dev/null
echo "[setup] skills: $(find "$CLAUDE_DIR/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"

[ -f "$SRC/CLAUDE.md" ] && cp "$SRC/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

CLAUDE_BIN="$(command -v claude || echo /conductor/bin/claude)"
if [ -x "$CLAUDE_BIN" ]; then
  while IFS= read -r m; do
    case "$m" in ""|\#*) continue ;; esac
    "$CLAUDE_BIN" plugin marketplace add "$m" >/dev/null 2>&1 || echo "[setup] marketplace failed: $m"
  done < "$SRC/marketplaces.txt"
  while IFS= read -r p; do
    case "$p" in ""|\#*) continue ;; esac
    "$CLAUDE_BIN" plugin install "$p" --scope user >/dev/null 2>&1 || echo "[setup] plugin failed: $p"
  done < "$SRC/plugins.txt"
  echo "[setup] plugins: $("$CLAUDE_BIN" plugin list 2>/dev/null | grep -c '@' || echo 0)"
fi

# Repo setup scripts call `vercel env pull`; the CLI is absent from the cloud
# image and authenticates from VERCEL_TOKEN in the Cloud Computer environment.
if [ -n "${VERCEL_TOKEN:-}" ] && ! command -v vercel >/dev/null 2>&1; then
  npm i -g vercel@latest >/dev/null 2>&1 && echo "[setup] vercel CLI installed" \
    || echo "[setup] vercel CLI install failed"
fi

exit 0
