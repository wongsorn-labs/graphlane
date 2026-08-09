#!/usr/bin/env bash
# Deterministic edge condition: block destructive commands regardless of what the model decided.
# Exit 2 = block the tool call and tell Claude why.
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))')

block() { echo "BLOCKED by graph policy: $1" >&2; exit 2; }

case "$cmd" in
  *"git push"*)            block "pushing is a human action, not an agent action" ;;
  *"rm -rf"*)              block "recursive delete" ;;
  *"DROP TABLE"*|*"drop table"*) block "destructive SQL" ;;
  *"npm publish"*|*"pypi upload"*) block "publishing is a human action" ;;
  *".env"*)                block "do not read or modify .env" ;;
esac
exit 0
