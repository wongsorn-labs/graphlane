# Changelog

All notable changes to graphlane are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

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
