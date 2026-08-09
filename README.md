# graphlane

> Every agent stays in its lane. A Claude Code plugin that runs subagents as a fixed
> pipeline — research, design, human approval, build, review — with hooks that block instead of hope.

Most multi-agent setups are a group chat with extra steps. This one is a graph: fixed nodes,
fixed edges, state on disk, and conditions that are actual shell exit codes.

```
/graphlane:mission  →  researcher  →  architect  →  [human approval]  →  builder  ⇄  reviewer  →  ship
                              └──────────  .mission/<slug>/  ──────────┘
```

## Install

> **Before you install:** the moment graphlane is installed, its `guard-bash.sh` hook blocks
> `git push` and `npm publish` in **every** project you use Claude Code in — not just the repo
> you're working on right now. That's deliberate (see "Known limits"), but it's a standing
> workflow change, not a per-repo opt-in. If you only want that behavior in specific projects,
> skip `/plugin install` and use `--plugin-dir` per-session instead (below) — it only applies
> for that one session.

graphlane is a Claude Code plugin. Add this repo as a marketplace, then install the plugin:

```
/plugin marketplace add wongsorn-labs/graphlane
/plugin install graphlane@graphlane
```

To hack on it locally, or to scope it to one project instead of installing it globally, point
Claude Code straight at your clone instead:

```bash
git clone https://github.com/wongsorn-labs/graphlane
claude --plugin-dir ./graphlane
```

**Required before first use:** edit `scripts/after-edit.sh` (in your clone, before installing —
plugin files aren't meant to be hand-edited after install) and replace the placeholder commands
with your project's real lint / typecheck. Shipped as-is it detects `tsconfig.json`, an ESLint
config, or `pyproject.toml`/`ruff.toml` and runs the matching tool — and says so out loud, rather
than silently passing, when none of those are present.

In the project where you use graphlane, add `.mission/` to `.gitignore` — or commit it if you
want the audit trail.

## Use

```
/graphlane:mission add-2fa เพิ่ม 2FA แบบ TOTP ให้หน้า login โดยไม่แตะ session เดิม
```

The router creates `.mission/add-2fa/`, then walks the nodes in order. It stops at step 4 and
waits for you to type `approve` before a single file gets written.

## Worked example

This is a real run, not a mockup — a throwaway repo with one 11-line `cli.py`, no tests, no
packaging, invoked exactly like this:

```
/graphlane:mission add-version-flag เพิ่มแฟลก --version ให้ cli.py พิมพ์ 1.0.0 แล้ว exit
```

Steps 1–3 run (brief → researcher → architect), then it stops at the human checkpoint:

```
**HUMAN CHECKPOINT**

Step list from plan.md:
1. cli.py — insert a new branch as the first statement after `args = sys.argv[1:]`, before
   the existing `if not args:`:
       if "--version" in args:
           print("1.0.0")
           return
2. cli.py — make no other edits (existing branches, import, __main__ guard stay untouched).
3. test_cli.py (new file, repo root) — unittest module driving cli.py via subprocess,
   covering --version, --version combined with other args (both positions), no-args,
   unknown-args, and --version=2 (should NOT match).
4. No other file changes.

HIGH-IMPACT section (verbatim):
> Nothing here touches auth, data deletion, migrations, billing, or a published API...
> - Deliberate omission of sys.exit()...
> - --version becomes a reserved token...
> - New file executes the Python interpreter...

approve / revise / abort?
```

Typing `approve` runs builder → reviewer and ships:

```
Mission summary: add-version-flag

Shipped
- cli.py: added `if "--version" in args: print("1.0.0"); return` as the first check in
  main(), ahead of the existing no-args branch. No sys.exit(), 3-line diff.
- test_cli.py (new): 6 stdlib unittest cases — --version alone, combined with other args
  in both positions, no-args, unknown-args, and --version=2 as a negative case.

Reviewer findings — VERDICT: PASS, no blockers. 4 non-blocking nits: no test pins the
case-insensitive-alias decision, no test asserts stderr == "", and running the suite
leaves an untracked __pycache__/ (pre-existing gitignore gap, unrelated to this change).

Still open
- .mission/ and __pycache__/ are untracked — left out of the commit since they're process
  artifacts, not the code deliverable.
```

The staged diff is exactly what the plan promised, nothing more:

```diff
+    if "--version" in args:
+        print("1.0.0")
+        return
```

The reviewer didn't just re-read the diff — it independently ran the test suite, tried
adversarial inputs (`--Version`, `--version=`, empty-string args, embedded whitespace), and
mutation-tested the test suite itself against 11 hand-introduced bugs (killed 7, logged the 4
survivors as findings instead of hiding them). Full detail lands in `.mission/<slug>/review.md`
and `artifacts.md`, alongside `brief.md`, `facts.md`, and `plan.md`.

> **A real bug this run surfaced (now fixed):** the mission slug first came out as `เพิ่มแฟลก` (a
> Thai word from the goal text) instead of the `add-version-flag` token typed first. Root cause,
> confirmed with an isolated debug command: Claude Code's `$1` positional substitution returns
> the *second* whitespace-separated token, not the first — reproducible with plain ASCII, not
> Thai-specific. `commands/mission.md` no longer uses `$1`; it has the model extract the slug from
> `$ARGUMENTS` itself instead, which was correct in every test. See `CLAUDE.md` "Known gaps".

## How it maps to the graph

| Node | Where it lives | What enforces it |
|---|---|---|
| Router | `commands/mission.md` | fixed step list — the model does not choose the path |
| Researcher | `agents/researcher.md` | no `Write` tool, so it physically cannot code |
| Architect | `agents/architect.md` | no `Edit` tool, plans only |
| Builder | `agents/builder.md` | must STOP if `plan.md` is missing |
| Private work area | each subagent's own context | main thread sees only the summary |
| Shared state | `.mission/<slug>/*.md` | fixed file schema per node |
| Integrator | the main thread | reads state, decides what moves next |
| Reviewer | `agents/reviewer.md` + `scripts/after-edit.sh` | runs the tests itself, doesn't trust the builder |
| Conditions | `VERDICT: PASS`/`FAIL` + `scripts/guard-bash.sh` | hook exits 2 → tool call is blocked |
| Human checkpoint | step 4 of `/graphlane:mission` | plus Claude Code's own permission prompts |
| Ship | stage + commit message | `git push` is blocked by hook, on purpose |
| Manifest | `.claude-plugin/plugin.json` | plugin identity, version, namespace (`graphlane:...`) |
| Self-hosted marketplace | `.claude-plugin/marketplace.json` | lets this repo be added directly via `/plugin marketplace add` |
| Hook wiring | `hooks/hooks.json` | `PreToolUse:Bash` → `guard-bash.sh`, `PostToolUse:Edit\|Write` → `after-edit.sh` |

## Design principles

- **one job per node** — enforced by the `tools:` frontmatter, not by asking politely
- **pass structured state** — files with a schema, not pasted transcripts
- **design the exit** — every node knows when to STOP; builder⇄reviewer caps at 3 rounds
- **block, don't hope** — the conditions that matter are shell hooks, not prompt text

## Known limits

- The human checkpoint is *soft* — it relies on the model obeying step 4. The hard version is a
  `PreToolUse` hook on `Edit|Write` that requires `.mission/<slug>/APPROVED`. See `CLAUDE.md`.
- Interactive dev-loop tool. For a headless service, use the Agent SDK instead.
- Start with researcher + builder + reviewer. Add the architect once you notice plans going wrong.
- As a plugin, `guard-bash.sh` applies to *every* project you install graphlane into, not just
  this repo — see the install-time warning above. `--plugin-dir` scopes it to one session instead.

## Requirements

Claude Code with plugin support, bash, and `python3` (used by `guard-bash.sh` to parse hook input).

## License

MIT
