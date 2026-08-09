# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Not a library. Not a framework. A **Claude Code plugin** — install it and its nodes are
available in any project as `/graphlane:mission` and friends. It used to be a `.claude/` folder
you copied by hand; it is now installed via `/plugin install graphlane@graphlane`, but the
content and the philosophy are unchanged. Everything outside `agents/`, `commands/`, `hooks/`,
`scripts/`, and `.claude-plugin/` is documentation.

Because of that:
- Do not add a build step, a package manager, or a runtime dependency.
- Do not convert the agent definitions into code. They are Markdown on purpose.
- Anything that only works on the author's machine does not belong here.
- Plugin component directories (`agents/`, `commands/`, `hooks/`) must stay at the plugin
  root, never nested inside `.claude-plugin/`. Only `plugin.json` and `marketplace.json` go there.

## Commands

There is no build, lint, or test suite for the repo itself — see "What this repo is" above.
The things worth running directly:

```bash
# Exercise guard-bash.sh the same way Claude Code's PreToolUse hook does.
# It reads {"tool_input":{"command": "..."}} on stdin; exit 2 means blocked.
echo '{"tool_input":{"command":"git push origin main"}}' | scripts/guard-bash.sh; echo "exit: $?"

# Exercise after-edit.sh the same way the PostToolUse hook does.
CLAUDE_PROJECT_DIR="$PWD" scripts/after-edit.sh

# Load the plugin from a local clone without installing it, to test a change in a real project.
claude --plugin-dir /path/to/graphlane

# Validate the manifest/marketplace shape before pushing (matches the community-submission check).
claude plugin validate .
```

There is no unit-test harness for the hook scripts (see "Known gaps"); the manual commands above
are the equivalent. The only real end-to-end test is running `/graphlane:mission <slug> <goal>`
(via `--plugin-dir`) against a throwaway branch of a real project and reading the resulting
`.mission/<slug>/*.md` files.

## The model

```
/graphlane:mission (router — deterministic, not an agent)
   └─ researcher ──┐
      architect ───┤→ .mission/<slug>/  (shared state, on disk)
      builder ─────┘
         ↓
      reviewer → VERDICT: PASS | FAIL
         ↓
      human checkpoint → ship
```

Wired in `hooks/hooks.json`: `PreToolUse` on `Bash` → `${CLAUDE_PLUGIN_ROOT}/scripts/guard-bash.sh`
(can block the call with exit 2); `PostToolUse` on `Edit|Write` →
`${CLAUDE_PLUGIN_ROOT}/scripts/after-edit.sh` (feeds lint/type output back to Claude, never
blocks). `CLAUDE_PLUGIN_ROOT` is where Claude Code installed the plugin, not the user's project —
use `CLAUDE_PROJECT_DIR` inside the scripts themselves for that.

Four principles, in priority order:

1. **One job per node.** Enforced by the `tools:` field in each agent's frontmatter, not by
   asking nicely in the prompt. Researcher has no Write. Architect has no Edit. Reviewer
   cannot fix what it finds. If you loosen a `tools:` list, you have broken the design.
2. **Pass structured state.** Nodes talk through files with a fixed shape in `.mission/<slug>/`
   (`brief.md`, `facts.md`, `plan.md`, `artifacts.md`, `review.md`). Never by pasting long
   transcripts between agents.
3. **Design the exit.** Every agent must say when to STOP. The builder↔reviewer loop caps at
   3 rounds and then escalates to the human.
4. **Block, don't hope.** Conditions that matter are shell hooks with exit code 2, not
   instructions the model may or may not follow.

## Decisions already made — do not relitigate

- **The router is a slash command, not an agent.** Model-chosen routing was rejected: an
  if/else is cheaper and more reliable than asking an LLM which node comes next.
- **Shared state is plain files, not a database.** It makes the graph inspectable and diffable,
  and it survives a crashed session.
- **`git push` and `npm publish` are blocked by hook.** Shipping is a human action. If someone
  wants to relax this, it should be their explicit local change, not the default.
- **Architect uses opus, builder uses sonnet, reviewer uses opus.** Judgement-heavy nodes get
  the stronger model; execution against an approved plan does not need it.
- **The word "Claude" is kept out of the project name** (trademark). It belongs in the
  description, not the package name.
- **Distributed as a Claude Code plugin, installed once per machine, not copied per project.**
  Content and structure otherwise unchanged from the original `.claude/`-folder template — only
  the install mechanism changed. This is a one-way door: `guard-bash.sh` now applies to *every*
  project the plugin is installed into, not just the repo you happened to copy it from. Document
  that consequence anywhere install is explained (see `README.md`), don't just let people find out.
- **This repo doubles as its own marketplace** (`.claude-plugin/marketplace.json` with a single
  plugin entry, `source: "./"`). No separate marketplace repo. Keep it that way unless a second
  plugin is added to this repo, which "One job per node" argues against.

## Known gaps

- **The human checkpoint is soft.** Step 4 of `/graphlane:mission` relies on the model stopping
  when told. The hard version is a `PreToolUse` hook on `Edit|Write` that exits 2 unless
  `.mission/<slug>/APPROVED` exists. Not implemented yet — good first contribution.
- **`after-edit.sh` ships with guessed commands.** Users must replace them with their real
  lint/typecheck, in their own clone, before installing — a plugin's files aren't meant to be
  hand-edited post-install. Document this loudly; do not silently make it a no-op.
- **Interactive only.** This is a dev-loop tool. Headless service use needs the Agent SDK, and
  that is out of scope for this repo.
- No tests for the hook scripts yet.
- Not yet submitted to any marketplace beyond its own self-hosted one — installable today only
  via `/plugin marketplace add wongsorn-labs/graphlane` or `--plugin-dir`.

## Conventions

- Agent files: `agents/<role>.md`, frontmatter needs `name`, `description`, `tools`, `model`.
- Keep each agent under ~40 lines. If a role needs more, it is probably two roles.
- Prompts are imperative and negative-first: state what the node must NOT do before what it does.
- Shell scripts: bash, `set -e` off deliberately (a hook that dies must not block the user),
  always `exit 0` on the non-blocking path.
- Hook commands in `hooks/hooks.json` use exec form (`command` + `args: []`) with
  `${CLAUDE_PLUGIN_ROOT}`, not shell-string form — avoids shell re-parsing of the substituted path.
- Docs in English; the maintainer may write issues in Thai — that is fine, answer in kind.

## Working in this repo

- When changing an agent's behaviour, update `README.md`'s mapping table in the same commit.
- Test a change with `claude --plugin-dir /path/to/graphlane` in a throwaway project, then run
  `/graphlane:mission` end-to-end. Reading the diff is not enough — the failure modes here are
  behavioural.
- Do not commit `.mission/` from your own test runs.
- Bump `version` in `.claude-plugin/plugin.json` when you ship a behavioural change — installed
  users only pick up updates once the version moves.
