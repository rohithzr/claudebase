---
name: sync-push
description: Use when the user wants to back up, save, or push their current Claude Code config to GitHub. Trigger with /sync-push.
argument-hint: "[--profile NAME] [--force] [--dry-run] [--include-global]"
user-invocable: true
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/sync-push.sh *), Read
version: 0.2.6
author: Rohit Hazra
license: MIT
compatibility: Requires Claude Code with Claudebase installed, Bash, jq, Git, and GitHub CLI.
tags: [claude-code, github, backup, configuration, sync-push]
---

# Config Sync Push

## Overview

Back up the current Claude Code project configuration to a private GitHub repository. Use this skill to save agents, skills, rules, hooks, and memory before moving machines or restoring a profile. Global settings remain opt-in, and local-only configuration is excluded.

## Prerequisites

Initialize Claudebase with `/sync-setup` first. Bash, jq, Git, and an authenticated GitHub CLI with repository access are required. Select the intended project and profile before running the script; use `--dry-run` to inspect the planned backup.

## What gets pushed

All syncable files from the current project and global config:
- `.mcp.json`, `.claude/settings.json`
- `.claude/agents/`, `.claude/commands/`, `.claude/skills/`
- `.claude/hooks/` (scripts, config, sounds)
- `.claude/rules/`, `.claude/agent-memory/`
- `.auto-memory/` (memory files)
- `~/.claude/settings.json` (global settings, opt-in via `--include-global`)

Files that are **never** pushed: `CLAUDE.md` (version-controlled with project), `settings.local.json`, `hooks-config.local.json`, conversations, sessions.

## Instructions

1. Parse the requested arguments and select the appropriate options below.
2. Run the documented script and check its result.

Parse user arguments and run the push script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/sync-push.sh [OPTIONS]
```

**Options:**
- `--profile NAME` — Push to a specific profile (default: active profile)
- `--force` — Skip multi-machine safety check and secret warnings
- `--dry-run` — Show what would be pushed without actually pushing
- `--include-global` — Also push `~/.claude/settings.json` (global settings are opt-in)

### Multi-machine warning

If the script warns about another machine having pushed more recently, advise the user to pull first (`/sync-pull`) or use `--force` if they're sure.

### Secret detection

If the script warns about potential secrets, tell the user which files were flagged and suggest reviewing them before using `--force`.

## Output

Report the target profile and whether the script pushed changes, found nothing to update, or only previewed the operation. Include any flagged file names and multi-machine warnings. Verify the script result before describing the remote backup as successful.

## Error Handling

Troubleshoot authentication or repository failures before retrying. If secret detection blocks the push, identify the flagged files for review without reproducing secret values. If another machine pushed more recently, recommend pulling and reconciling changes first; use `--force` only when explicitly requested.

## Examples

```text
/sync-push --dry-run
/sync-push --profile work
```

## Resources

- Read [the README](https://github.com/rohithzr/claudebase#readme) for installation, shared layers, and supported configuration paths.
- Read [the privacy policy](https://github.com/rohithzr/claudebase/blob/main/PRIVACY.md) for backup storage and credential handling.
- Read [the changelog](https://github.com/rohithzr/claudebase/blob/main/CHANGELOG.md) for changes affecting installed versions.

## User Arguments

Interpret the following input as arguments for the documented operation:

$ARGUMENTS
