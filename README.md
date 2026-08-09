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

graphlane is a Claude Code plugin. Add this repo as a marketplace, then install the plugin:

```
/plugin marketplace add wongsorn-labs/graphlane
/plugin install graphlane@graphlane
```

To hack on it locally instead, point Claude Code straight at your clone:

```bash
git clone https://github.com/wongsorn-labs/graphlane
claude --plugin-dir ./graphlane
```

**Required before first use:** edit `scripts/after-edit.sh` (in your clone, before installing —
plugin files aren't meant to be hand-edited after install) and replace the placeholder commands
with your project's real lint / typecheck. Shipped as-is it will quietly do nothing.

In the project where you use graphlane, add `.mission/` to `.gitignore` — or commit it if you
want the audit trail.

## Use

```
/graphlane:mission add-2fa เพิ่ม 2FA แบบ TOTP ให้หน้า login โดยไม่แตะ session เดิม
```

The router creates `.mission/add-2fa/`, then walks the nodes in order. It stops at step 4 and
waits for you to type `approve` before a single file gets written.

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
  this repo. Blocking `git push` / `npm publish` becomes a standing policy the moment you install
  it — know that before you install it in a project where you don't want that.

## Requirements

Claude Code with plugin support, bash, and `python3` (used by `guard-bash.sh` to parse hook input).

## License

MIT
