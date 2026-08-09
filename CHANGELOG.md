# Changelog

All notable changes to graphlane are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `scripts/test-hooks.sh` — plain-bash assertion harness for `guard-bash.sh` and
  `after-edit.sh` (block/allow patterns, config-gating, the "never blocks" invariant for
  after-edit.sh). No runtime behavior changed, so no version bump — dev tooling only.

## [0.1.1] - 2026-08-09

### Added

- `/graphlane:release <patch|minor|major> <what changed>` command — bumps `plugin.json`'s
  `version` and adds a matching `CHANGELOG.md` entry, run through Claude Code instead of a
  package script (this repo has no build step or package manager).

### Fixed

- `commands/mission.md` no longer uses `$1` for the mission slug — Claude Code's positional
  substitution was confirmed (via an isolated debug command) to return the second
  whitespace-separated token instead of the first, reproducible with plain ASCII. The router now
  extracts the slug from `$ARGUMENTS` itself.
- `scripts/after-edit.sh` now gates each tool on a real config file (`tsconfig.json`, an ESLint
  config, `pyproject.toml`/`ruff.toml`) instead of just `package.json`, and prints a one-line
  notice instead of silently passing when nothing matches.

### Changed

- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` descriptions, plus a new
  warning at the top of README's Install section, now state up front that installing graphlane
  blocks `git push` / `npm publish` in every project you use it in — not just buried in "Known
  limits" after the fact. `--plugin-dir` is documented as the way to scope it to one session.
- README's "Worked example" section now walks through a real end-to-end `/graphlane:mission` run
  (via `--plugin-dir` against a throwaway repo) instead of just a one-line invocation sample.

## [0.1.0] - 2026-08-09

### Changed

- Converted graphlane from a standalone `.claude/`-folder template into an installable
  Claude Code plugin. `agents/`, `commands/`, and `scripts/` moved to the plugin root; added
  `.claude-plugin/plugin.json` and a self-hosted `.claude-plugin/marketplace.json`
  (`source: "./"`); hooks migrated from `.claude/settings.json` to `hooks/hooks.json` using
  `${CLAUDE_PLUGIN_ROOT}` exec-form paths.
- Router is now invoked as `/graphlane:mission` (plugin namespace) instead of `/mission`.
- Install flow is now `/plugin marketplace add` + `/plugin install`, or `--plugin-dir` for
  local testing, instead of `cp -r .claude/`.

### Note

- Installing graphlane as a plugin makes `guard-bash.sh`'s `git push` / `npm publish` block a
  standing policy for every project the plugin is installed into, not just the repo it was
  copied from.
