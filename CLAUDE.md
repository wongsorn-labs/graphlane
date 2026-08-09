# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Not a library. Not a framework. A **template** that people copy into their own project.
The deliverable is the `.claude/` folder. Everything else is documentation.

Because of that:
- Do not add a build step, a package manager, or a runtime dependency.
- Do not convert the agent definitions into code. They are Markdown on purpose.
- Anything that only works on the author's machine does not belong here.

## Commands

There is no build, lint, or test suite for the repo itself — see "What this repo is" above.
The two things worth running directly:

```bash
# Exercise guard-bash.sh the same way Claude Code's PreToolUse hook does.
# It reads {"tool_input":{"command": "..."}} on stdin; exit 2 means blocked.
echo '{"tool_input":{"command":"git push origin main"}}' | .claude/scripts/guard-bash.sh; echo "exit: $?"

# Exercise after-edit.sh the same way the PostToolUse hook does.
CLAUDE_PROJECT_DIR="$PWD" .claude/scripts/after-edit.sh
```

There is no unit-test harness for the hook scripts (see "Known gaps"); the commands above are
the manual equivalent. The only real end-to-end test is running `/mission <slug> <goal>` against
a throwaway branch of a real project and reading the resulting `.mission/<slug>/*.md` files.

## The model

```
/mission (router — deterministic, not an agent)
   └─ researcher ──┐
      architect ───┤→ .mission/<slug>/  (shared state, on disk)
      builder ─────┘
         ↓
      reviewer → VERDICT: PASS | FAIL
         ↓
      human checkpoint → ship
```

Wired in `.claude/settings.json`: `PreToolUse` on `Bash` → `scripts/guard-bash.sh` (can block
the call with exit 2); `PostToolUse` on `Edit|Write` → `scripts/after-edit.sh` (feeds lint/type
output back to Claude, never blocks).

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

## Known gaps

- **The human checkpoint is soft.** Step 4 of `/mission` relies on the model stopping when told.
  The hard version is a `PreToolUse` hook on `Edit|Write` that exits 2 unless
  `.mission/<slug>/APPROVED` exists. Not implemented yet — good first contribution.
- **`after-edit.sh` ships with guessed commands.** Users must replace them with their real
  lint/typecheck. Document this loudly; do not silently make it a no-op.
- **Interactive only.** This is a dev-loop tool. Headless service use needs the Agent SDK, and
  that is out of scope for this repo.
- No tests for the hook scripts yet.

## Conventions

- Agent files: `.claude/agents/<role>.md`, frontmatter needs `name`, `description`, `tools`, `model`.
- Keep each agent under ~40 lines. If a role needs more, it is probably two roles.
- Prompts are imperative and negative-first: state what the node must NOT do before what it does.
- Shell scripts: bash, `set -e` off deliberately (a hook that dies must not block the user),
  always `exit 0` on the non-blocking path.
- Docs in English; the maintainer may write issues in Thai — that is fine, answer in kind.

## Working in this repo

- When changing an agent's behaviour, update `README.md`'s mapping table in the same commit.
- Test a change by running `/mission` end-to-end on a throwaway branch of a real project.
  Reading the diff is not enough — the failure modes here are behavioural.
- Do not commit `.mission/` from your own test runs.
