---
name: sync-pull
description: Use when the user wants to restore, download, or pull their Claude Code config from GitHub onto this machine. Trigger with /sync-pull.
argument-hint: "[--profile NAME] [--dry-run] [--no-backup] [--yes] [--include-global]"
user-invocable: true
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/sync-pull.sh *), Read
version: 0.2.6
author: Rohit Hazra
license: MIT
compatibility: Requires Claude Code with Claudebase installed, Bash, jq, Git, and GitHub CLI.
tags: [claude-code, github, backup, configuration, sync-pull]
---

# Config Sync Pull

## Overview

Restore saved Claude Code configuration from a private GitHub backup repository. Use this skill when moving to another machine or applying a saved profile. Shared configuration is applied first, followed by the selected profile and any enabled global settings.

## Prerequisites

Claudebase setup must be complete. Bash, jq, Git, and authenticated GitHub CLI access to the backup repository are required. Confirm the target profile and local destination. You can also preview the operation with `--dry-run` before applying changes.

## What happens

1. **Backup** — Current local config is backed up to plugin data directory (timestamped, keeps last 10)
2. **Apply shared** — Files from `shared/` directory are applied first (base layer)
3. **Apply profile** — Profile-specific files overlay on top (overrides shared where both exist)
4. **Apply global** — User-level settings from `global/` are applied to `~/.claude/`
5. **Verify** — JSON config files are validated for correct syntax

## Instructions

1. Parse the requested arguments and select the appropriate options below.
2. Run the documented script and check its result.

Parse user arguments and run the pull script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/sync-pull.sh [OPTIONS]
```

**Options:**
- `--profile NAME` — Pull a specific profile (default: active profile)
- `--dry-run` — Show what would be applied without writing any files
- `--no-backup` — Skip backup step (use with caution)
- `--yes` / `-y` — Skip confirmation prompt (auto-approve)
- `--include-global` — Also pull `~/.claude/settings.json` (global settings are opt-in)

### Profile switching

If the user specifies a different profile than their current one, this effectively switches their setup. Let them know which profile they're switching from/to.

### After pull

Tell the user:
- How many files were applied
- Any validation warnings
- That a backup was created (and where)
- They may need to restart Claude Code for some settings to take effect

## Output

Report the selected profile, applied file count, JSON validation warnings, and backup location from the script output. A dry run reports planned changes rather than completed restoration. Explain that a restart may be required for loaded Claude Code settings to take effect.

## Error Handling

Troubleshoot missing profiles and authentication failures before retrying. If JSON validation reports malformed configuration, identify the affected file and report the warning. Preserve the normal backup and confirmation steps unless the user explicitly requested the corresponding bypass options.

## Examples

```text
/sync-pull --dry-run
/sync-pull --profile work
```

## Resources

- Read [the README](https://github.com/rohithzr/claudebase#readme) for installation, shared layers, and supported configuration paths.
- Read [the privacy policy](https://github.com/rohithzr/claudebase/blob/main/PRIVACY.md) for backup storage and credential handling.
- Read [the changelog](https://github.com/rohithzr/claudebase/blob/main/CHANGELOG.md) for changes affecting installed versions.

## User Arguments

Interpret the following input as arguments for the documented operation:

$ARGUMENTS
