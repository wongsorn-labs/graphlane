---
description: Bump the plugin version and add a CHANGELOG.md entry — the manual release step, run through Claude Code instead of a script
argument-hint: <patch|minor|major> <what changed>
allowed-tools: Read, Edit, Bash
---

Bump type: `$1`
What changed: everything in $ARGUMENTS after `$1`

Do NOT reach for a build tool, npm script, or changelog generator. This command exists
precisely because this repo has none of those — see `CLAUDE.md`, "no build step, no
package manager". Do the steps yourself, in order.

1. If `$1` is not exactly `patch`, `minor`, or `major`, STOP and ask which one.
2. Read `.claude-plugin/plugin.json`. Note the current `version`.
3. Compute the new version by bumping the named part per semver (reset lower parts to 0).
4. Run `date +%Y-%m-%d` to get today's date — do not guess it.
5. Edit `.claude-plugin/plugin.json`: set `version` to the new value.
6. Edit `CHANGELOG.md`: insert a new `## [<new version>] - <date>` section immediately after
   `## [Unreleased]`, with the "what changed" text as a bullet under whichever Keep a Changelog
   category fits (`Added` / `Changed` / `Fixed` / `Removed`).
7. Do not commit or push. That is still an explicit, separate action.

Reply with: old version → new version, and the exact CHANGELOG entry you wrote.
