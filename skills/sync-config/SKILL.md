---
name: sync-config
description: Use when the user wants to view or change claudebase settings like global sync, agent skills sync, auto-push, or machine ID. Trigger with /sync-config.
argument-hint: "[show] | [set <key> <value>] | [get <key>] | [reset <key>]"
user-invocable: true
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/config-manager.sh *), Read
version: 0.2.6
author: Rohit Hazra
license: MIT
compatibility: Requires Claude Code with Claudebase installed and initialized, Bash, and jq.
tags: [claude-code, github, backup, configuration, sync-config]
---

# Config Sync Settings

## Overview

Inspect and customize the saved configuration used by Claudebase. Use this skill to control global settings sync, agent skill lock-file sync, automatic pushes, and machine identity without editing plugin state by hand.

## Prerequisites

Claudebase must be installed and initialized with `/sync-setup`. The configuration script requires Bash and jq. Read the current setting before changing it so the user can see the effect of the requested change.

## Instructions

1. Parse the requested arguments and select the appropriate options below.
2. Run the documented script and check its result.

Run the config manager script with the appropriate action:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/config-manager.sh ACTION [KEY] [VALUE]
```

### Actions

- **show** (default) — Display all current settings
- **set `<key>` `<value>`** — Change a setting
- **get `<key>`** — Read a single setting
- **reset `<key>`** — Remove a setting (revert to default)

### Configurable keys

| Key | Values | Description |
|-----|--------|-------------|
| `include_global` | `true`/`false` | Sync `~/.claude/settings.json` on push/pull |
| `sync_agent_skills` | `true`/`false` | Sync `skills-lock.json` (lock file only; prints install commands on pull) |
| `auto_push` | `true`/`false` | Auto-push config when a Claude Code session ends |
| `machine_id` | any string | Identifier for this machine (used in multi-machine warnings) |

### Common actions

- `/sync-config` — show all settings
- `/sync-config set include_global true` — enable global settings sync
- `/sync-config set auto_push false` — disable auto-push

## Output

For `show`, report the repository, active profile, settings, and state locations. For `get`, return the selected value. For `set` and `reset`, report the affected key and the script result; verify changes with the corresponding `get` action.

## Error Handling

If setup is missing, direct the user to `/sync-setup`. Troubleshoot unknown keys or invalid boolean values using the supported-key table. Boolean settings accept only `true` or `false`. Reset supports the three boolean keys; it does not reset `machine_id`.

## Examples

```text
/sync-config get auto_push
/sync-config set auto_push false
```

## Resources

- Read [the README](https://github.com/rohithzr/claudebase#readme) for installation, shared layers, and supported configuration paths.
- Read [the privacy policy](https://github.com/rohithzr/claudebase/blob/main/PRIVACY.md) for backup storage and credential handling.
- Read [the changelog](https://github.com/rohithzr/claudebase/blob/main/CHANGELOG.md) for changes affecting installed versions.

## User Arguments

Interpret the following input as arguments for the documented operation:

$ARGUMENTS
