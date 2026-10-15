---
name: sync-profiles
description: Use when the user wants to list, create, switch, delete, compare, or inspect config sync profiles. Trigger with /sync-profiles.
argument-hint: "<list|create|switch|delete|diff|info> [name] [--from existing]"
user-invocable: true
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-manager.sh *), Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/sync-pull.sh *), Read
version: 0.2.6
author: Rohit Hazra
license: MIT
compatibility: Requires Claude Code with Claudebase installed, Bash, jq, Git, and GitHub CLI.
tags: [claude-code, github, backup, configuration, sync-profiles]
---

# Config Sync Profiles

## Overview

Manage separate work, personal, and team configurations in the same private GitHub backup repository. Use profiles to inspect or compare saved setups, create a starting configuration, or restore a different profile onto this machine.

## Prerequisites

Install and initialize Claudebase first. Bash, jq, Git, and an authenticated GitHub CLI are required. The requested profile must exist for inspection or switching. Review local changes before switching because a switch applies the selected profile to this machine.

## Available actions

### List profiles
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-manager.sh list
```
Shows all profiles with file counts, last push time, and which is active.

### Create a profile
```bash
# Empty profile
bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-manager.sh create NAME

# Clone from existing profile
bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-manager.sh create NAME --from EXISTING
```
Creates a new profile. Use `--from` to clone an existing profile as a starting point.

### Switch to a profile
Switching means pulling a different profile's config:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/sync-pull.sh --profile NAME
```
This backs up current config, then applies the target profile. The active profile is updated automatically.

### Delete a profile
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-manager.sh delete NAME
```
Cannot delete the active profile. Switch to a different one first.

### Compare two profiles
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-manager.sh diff NAME1 NAME2
```
Shows files that exist in only one profile or differ between them.

### Profile info
```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/profile-manager.sh info NAME
```
Shows metadata and contents of a specific profile.

## Instructions

1. Parse the user's action from $ARGUMENTS and identify the target profile.
2. Run the appropriate command above and check its result.

If the user says "switch" to a profile, use the pull script with `--profile` rather than the profile-manager (since switching = pulling a different profile).

If no action is specified, default to `list`.

## Output

Report profile names and the active profile for listing. Creation and deletion return the script result. Comparison identifies differing or missing files. Switching reports the applied profile, file counts, backup location, and validation warnings returned by the pull script.

## Error Handling

Troubleshoot missing profiles with `list` before retrying. The active profile cannot be deleted; switch to another profile first. If GitHub authentication or repository access fails, report that failure and ask the user to restore access before repeating the operation.

## Examples

```text
/sync-profiles list
/sync-profiles create work --from default
```

## Resources

- Read [the README](https://github.com/rohithzr/claudebase#readme) for installation, shared layers, and supported configuration paths.
- Read [the privacy policy](https://github.com/rohithzr/claudebase/blob/main/PRIVACY.md) for backup storage and credential handling.
- Read [the changelog](https://github.com/rohithzr/claudebase/blob/main/CHANGELOG.md) for changes affecting installed versions.

## User Arguments

Interpret the following input as arguments for the documented operation:

$ARGUMENTS
