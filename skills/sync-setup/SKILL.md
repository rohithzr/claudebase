---
name: sync-setup
description: Use when the user wants to set up config sync for the first time, connect to GitHub, or re-initialize the backup repo. Trigger with /sync-setup.
argument-hint: "[repo-name] [profile-name]"
user-invocable: true
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/ensure-repo.sh *), Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/sync-push.sh *), Read
version: 0.2.6
author: Rohit Hazra
license: MIT
compatibility: Requires Claude Code with Claudebase installed, Bash, jq, Git, and GitHub CLI.
tags: [claude-code, github, backup, configuration, sync-setup]
---

# Config Sync Setup

## Overview

Initialize a private GitHub repository for backing up Claude Code configuration and perform the first push. Use this skill for a new installation or an existing backup repository. A successful setup gives later push, pull, status, and profile commands their saved repository context.

## Prerequisites

Install Claudebase, Bash, jq, Git, and GitHub CLI. Authenticate GitHub CLI before repository creation. The account needs permission to create the requested private repository or access an existing one. Choose the project directory whose configuration should be backed up.

## Setup sequence

1. Verifies `gh` CLI is installed and authenticated
2. Creates a **private** GitHub repo for config storage (or connects to existing)
3. Initializes the repo structure with a default profile
4. Performs the first push of your current Claude Code config

## Instructions

1. Parse the requested arguments and select the appropriate options below.
2. Run the documented script and check its result.

Run the setup script. Parse user arguments for custom repo name and profile:

- First argument (if provided): repo name (default: `claude-config`)
- Second argument (if provided): initial profile name (default: `default`)

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/ensure-repo.sh REPO_NAME PROFILE_NAME
```

Replace REPO_NAME and PROFILE_NAME with the user's values or defaults.

### If `gh` is not installed

Guide the user to install it:
- **macOS**: `brew install gh`
- **Linux**: `sudo apt install gh` or `sudo dnf install gh`
- **Windows**: `winget install --id GitHub.cli`

Then authenticate: `gh auth login`

### After setup succeeds

Run the first push automatically:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/sync-push.sh --profile PROFILE_NAME
```

Tell the user what was synced and show all available commands: `/sync-push`, `/sync-pull`, `/sync-status`, `/sync-profiles`, `/sync-config`.

## Output

Report the repository selected or created, the initial profile, and the first push result. Verify setup succeeded before starting the first push. If setup succeeds but the push fails, distinguish those outcomes and explain how to retry the backup with `/sync-push`.

## Error Handling

Troubleshoot missing GitHub CLI with the installation commands in Instructions, and follow its authentication guidance when access fails. Report repository creation or clone errors rather than claiming setup completed. If the first push flags secrets, identify the files for review without including secret values.

## Examples

```text
/sync-setup
/sync-setup claude-config work
```

## Resources

- Read [the README](https://github.com/rohithzr/claudebase#readme) for installation, shared layers, and supported configuration paths.
- Read [the privacy policy](https://github.com/rohithzr/claudebase/blob/main/PRIVACY.md) for backup storage and credential handling.
- Read [the changelog](https://github.com/rohithzr/claudebase/blob/main/CHANGELOG.md) for changes affecting installed versions.

## User Arguments

Interpret the following input as arguments for the documented operation:

$ARGUMENTS
