# graphlane

> Every agent stays in its lane. A `.claude/` setup that runs Claude Code subagents as a fixed
> pipeline — research, design, human approval, build, review — with hooks that block instead of hope.

Most multi-agent setups are a group chat with extra steps. This one is a graph: fixed nodes,
fixed edges, state on disk, and conditions that are actual shell exit codes.

```
/mission  →  researcher  →  architect  →  [human approval]  →  builder  ⇄  reviewer  →  ship
                    └──────────  .mission/<slug>/  ──────────┘
```

## Install

```bash
cp -r graphlane/.claude /path/to/your/repo/
cp graphlane/CLAUDE.md  /path/to/your/repo/   # optional but recommended
cd /path/to/your/repo
chmod +x .claude/scripts/*.sh
echo ".mission/" >> .gitignore   # or commit it if you want the audit trail
```

**Required before first use:** edit `.claude/scripts/after-edit.sh` and replace the placeholder
commands with your project's real lint / typecheck. Shipped as-is it will quietly do nothing.

## Use

```
/mission add-2fa เพิ่ม 2FA แบบ TOTP ให้หน้า login โดยไม่แตะ session เดิม
```

The router creates `.mission/add-2fa/`, then walks the nodes in order. It stops at step 4 and
waits for you to type `approve` before a single file gets written.

## How it maps to the graph

| Node | Where it lives | What enforces it |
|---|---|---|
| Router | `.claude/commands/mission.md` | fixed step list — the model does not choose the path |
| Researcher | `agents/researcher.md` | no `Write` tool, so it physically cannot code |
| Architect | `agents/architect.md` | no `Edit` tool, plans only |
| Builder | `agents/builder.md` | must STOP if `plan.md` is missing |
| Private work area | each subagent's own context | main thread sees only the summary |
| Shared state | `.mission/<slug>/*.md` | fixed file schema per node |
| Integrator | the main thread | reads state, decides what moves next |
| Reviewer | `agents/reviewer.md` + `scripts/after-edit.sh` | runs the tests itself, doesn't trust the builder |
| Conditions | `VERDICT: PASS`/`FAIL` + `scripts/guard-bash.sh` | hook exits 2 → tool call is blocked |
| Human checkpoint | step 4 of `/mission` | plus Claude Code's own permission prompts |
| Ship | stage + commit message | `git push` is blocked by hook, on purpose |

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

## Requirements

Claude Code, bash, and `python3` (used by `guard-bash.sh` to parse hook input).

## License

MIT
