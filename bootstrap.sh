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

CLAUDE_BIN="$(command -v claude || echo /conductor/bin/claude)"
if [ -x "$CLAUDE_BIN" ]; then
  # Print the tool's own error. A silent failure here costs far more to debug
  # than the two extra lines of log it would have saved.
  while IFS= read -r m; do
    case "$m" in ""|\#*) continue ;; esac
    out=$("$CLAUDE_BIN" plugin marketplace add "$m" 2>&1) \
      || echo "[setup] marketplace failed: $m — $(printf '%s' "$out" | tail -1)"
  done < "$SRC/marketplaces.txt"
  while IFS= read -r p; do
    case "$p" in ""|\#*) continue ;; esac
    out=$("$CLAUDE_BIN" plugin install "$p" --scope user 2>&1) \
      || echo "[setup] plugin failed: $p — $(printf '%s' "$out" | tail -1)"
  done < "$SRC/plugins.txt"
  echo "[setup] plugins: $("$CLAUDE_BIN" plugin list 2>/dev/null | grep -c '@' || echo 0)"
fi

# The cloud image ships no vercel CLI, so `vercel env pull` fails there unless
# we install it. VERCEL_TOKEN comes from the Cloud Computer environment, which
# is the only variable store that spans every repository.
if [ -n "${VERCEL_TOKEN:-}" ] && ! command -v vercel >/dev/null 2>&1; then
  npm i -g vercel@latest >/dev/null 2>&1 && echo "[setup] vercel CLI installed" \
    || echo "[setup] vercel CLI install failed"
fi

# Pull each project's own variables rather than duplicating secrets per repo.
# Repos whose setup script already pulls .env.local keep theirs: this runs
# first, and the file-exists guard stops a second pull from overwriting it.
WS="${CONDUCTOR_WORKSPACE_PATH:-$PWD}"
if [ -n "${VERCEL_TOKEN:-}" ] && command -v vercel >/dev/null 2>&1 \
   && [ -f "$WS/.vercel/project.json" ] && [ ! -f "$WS/.env.local" ]; then
  if ( cd "$WS" && vercel env pull .env.local --environment=production --yes \
         --token "$VERCEL_TOKEN" >/dev/null 2>&1 ); then
    echo "[setup] .env.local pulled from Vercel"
  else
    echo "[setup] vercel env pull failed"
  fi
fi

exit 0
