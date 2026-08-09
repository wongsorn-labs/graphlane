#!/usr/bin/env bash
# Fast feedback edge: every write is immediately checked. Output is fed back to Claude.
# Replace the commands below with your project's real lint / typecheck.
cd "$CLAUDE_PROJECT_DIR" || exit 0

ran=0

if [ -f tsconfig.json ]; then
  ran=1
  if command -v npx >/dev/null 2>&1; then
    npx --no-install tsc --noEmit 2>&1 | tail -20
  else
    echo "after-edit.sh: tsconfig.json found but npx isn't on PATH — can't run tsc."
  fi
fi

if compgen -G ".eslintrc*" >/dev/null || compgen -G "eslint.config.*" >/dev/null; then
  ran=1
  if command -v npx >/dev/null 2>&1; then
    npx --no-install eslint . --quiet 2>&1 | tail -20
  else
    echo "after-edit.sh: eslint config found but npx isn't on PATH — can't run eslint."
  fi
fi

if [ -f pyproject.toml ] || [ -f ruff.toml ] || [ -f .ruff.toml ]; then
  ran=1
  if command -v ruff >/dev/null 2>&1; then
    ruff check . 2>&1 | tail -20
  else
    echo "after-edit.sh: pyproject.toml/ruff.toml found but ruff isn't on PATH — can't run ruff."
  fi
fi

if [ "$ran" -eq 0 ]; then
  echo "after-edit.sh: no tsconfig.json / eslint config / pyproject.toml (or ruff.toml) found in" \
       "this project — nothing to check yet. Edit scripts/after-edit.sh with this project's real" \
       "lint/typecheck commands."
fi

exit 0
