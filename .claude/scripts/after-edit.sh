#!/usr/bin/env bash
# Fast feedback edge: every write is immediately checked. Output is fed back to Claude.
# Replace these with your project's real commands.
cd "$CLAUDE_PROJECT_DIR" || exit 0

if [ -f package.json ]; then
  npx --no-install tsc --noEmit 2>&1 | tail -20
  npx --no-install eslint . --quiet 2>&1 | tail -20
elif [ -f pyproject.toml ]; then
  ruff check . 2>&1 | tail -20
fi
exit 0
