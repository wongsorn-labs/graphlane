#!/usr/bin/env bash
# Manual test harness for guard-bash.sh and after-edit.sh. Plain bash assertions,
# no test framework — this repo has no build step or package manager (see CLAUDE.md).
# Run: scripts/test-hooks.sh
set -u
cd "$(dirname "$0")/.." || exit 1

pass=0
fail=0

payload() {
  python3 -c 'import json,sys; print(json.dumps({"tool_input":{"command":sys.argv[1]}}))' "$1"
}

assert_block() {
  local desc="$1" cmd="$2" out status
  out=$(payload "$cmd" | scripts/guard-bash.sh 2>&1)
  status=$?
  if [ "$status" -eq 2 ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: $desc — expected exit 2, got $status. Output: $out"
  fi
}

assert_allow() {
  local desc="$1" cmd="$2" out status
  out=$(payload "$cmd" | scripts/guard-bash.sh 2>&1)
  status=$?
  if [ "$status" -eq 0 ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: $desc — expected exit 0, got $status. Output: $out"
  fi
}

assert_after_edit() {
  local desc="$1" dir="$2" expect_substr="$3" out status
  # Restricted PATH: keeps bash/coreutils/python3 findable, excludes wherever
  # npx/ruff/etc happen to live on this machine, so the "tool unavailable" branch
  # is exercised deterministically regardless of what's installed locally.
  out=$(env -i HOME="$HOME" PATH="/usr/bin:/bin" CLAUDE_PROJECT_DIR="$dir" \
        scripts/after-edit.sh 2>&1)
  status=$?
  if [ "$status" -ne 0 ]; then
    fail=$((fail + 1))
    echo "FAIL: $desc — after-edit.sh must always exit 0 (non-blocking), got $status"
    return
  fi
  if [ -n "$expect_substr" ] && [[ "$out" != *"$expect_substr"* ]]; then
    fail=$((fail + 1))
    echo "FAIL: $desc — expected output to contain: $expect_substr"
    echo "  actual: $out"
    return
  fi
  pass=$((pass + 1))
}

# --- guard-bash.sh: blocked commands ---
assert_block "git push, bare"                    "git push"
assert_block "git push with remote/branch"       "git push origin main"
assert_block "git push mid-command"              "echo hi && git push origin feature-branch"
assert_block "rm -rf, bare"                       "rm -rf"
assert_block "rm -rf with path"                  "rm -rf /tmp/foo"
assert_block "DROP TABLE, uppercase"             "DROP TABLE users;"
assert_block "drop table, lowercase"             "drop table users;"
assert_block "npm publish"                       "npm publish"
assert_block "pypi upload"                       "pypi upload dist/*"
assert_block ".env read"                         "cat .env"
# Known over-match: the pattern is a plain substring on ".env", so any filename
# containing that substring blocks too. Documenting the real behavior, not a bug fix.
assert_block ".env.example (substring over-match, documented behavior)" "cat .env.example"

# --- guard-bash.sh: allowed commands ---
assert_allow "git status"                        "git status"
assert_allow "npm install"                       "npm install"
assert_allow "rm without -rf"                    "rm file.txt"
assert_allow "unrelated SQL"                     "SELECT * FROM users"
assert_allow "plain ls"                          "ls -la"
assert_allow "empty command string"              ""

# malformed / missing tool_input.command — must not crash, must not block
out=$(echo '{}' | scripts/guard-bash.sh 2>&1); status=$?
if [ "$status" -eq 0 ]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  echo "FAIL: missing tool_input field — expected exit 0, got $status. Output: $out"
fi

# --- after-edit.sh: config-gating and the loud no-op notice ---
empty_dir=$(mktemp -d)
assert_after_edit "empty project — loud no-op, not silent" "$empty_dir" "nothing to check yet"

pkgjson_dir=$(mktemp -d)
echo '{"name":"x"}' > "$pkgjson_dir/package.json"
assert_after_edit "package.json alone is not enough to trigger tsc/eslint" \
  "$pkgjson_dir" "nothing to check yet"

tsconfig_dir=$(mktemp -d)
echo '{"compilerOptions":{"strict":true}}' > "$tsconfig_dir/tsconfig.json"
assert_after_edit "tsconfig.json present, npx unavailable" "$tsconfig_dir" "can't run tsc"

eslint_dir=$(mktemp -d)
echo '{}' > "$eslint_dir/.eslintrc.json"
assert_after_edit "eslint config present, npx unavailable" "$eslint_dir" "can't run eslint"

pyproject_dir=$(mktemp -d)
printf '[project]\nname = "x"\n' > "$pyproject_dir/pyproject.toml"
assert_after_edit "pyproject.toml present, ruff unavailable" "$pyproject_dir" "can't run ruff"

rufftoml_dir=$(mktemp -d)
echo 'line-length = 100' > "$rufftoml_dir/ruff.toml"
assert_after_edit "ruff.toml alone present, ruff unavailable" "$rufftoml_dir" "can't run ruff"

rm -rf "$empty_dir" "$pkgjson_dir" "$tsconfig_dir" "$eslint_dir" "$pyproject_dir" "$rufftoml_dir"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
