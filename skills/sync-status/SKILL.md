---
name: sync-status
description: Use when the user wants to check what config has changed, see sync status, or compare local vs remote config. Trigger with /sync-status.
user-invocable: true
allowed-tools: Bash(bash ${CLAUDE_PLUGIN_ROOT}/scripts/diff-config.sh *), Read
version: 0.2.6
author: Rohit Hazra
license: MIT
compatibility: Requires Claude Code with Claudebase installed, Bash, jq, Git, and GitHub CLI.
tags: [claude-code, github, backup, configuration, sync-status]
---

# Config Sync Status

## Overview

Compare the current local Claude Code configuration with its saved GitHub profile. Use this skill before deciding whether to push local edits or restore remote changes. It reports differences without applying the saved configuration or publishing local changes.

## Prerequisites

Claudebase must be initialized, with Bash, jq, Git, and authenticated GitHub CLI access to the backup repository. The requested profile must exist. Run from the intended project directory so the comparison uses the correct local configuration.

## Instructions

1. Parse the requested arguments and select the appropriate options below.
2. Run the documented script and check its result.

Run the diff script:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/diff-config.sh --profile PROFILE_NAME
```

If the user doesn't specify a profile, omit the `--profile` flag (uses active profile).

### Interpreting output

The script shows each tracked file/directory with a status:

- `+ local only` (green) — Exists locally but hasn't been pushed yet
- `+ remote only` (cyan) — Exists in the repo but hasn't been pulled yet
- `~ modified` (yellow) — Exists in both but differs

### Recommendations

Based on the output, suggest the appropriate action:
- Local-only files → suggest `/sync-push`
- Remote-only files → suggest `/sync-pull`
- Modified files → suggest checking what changed, then push or pull

## Output

Report each local-only, remote-only, and modified file or directory using the meanings below. Summarize the recommended next action based on the comparison. Check the script result before claiming configurations match; a failed comparison does not establish that no changes exist.

## Error Handling

Troubleshoot incomplete setup with `/sync-setup`. For a missing profile, suggest listing profiles with `/sync-profiles list`. If authentication or repository refresh fails, report the failure and restore access before rerunning the comparison. Keep recommendations separate from executing a push or pull.

## Examples

```text
/sync-status
/sync-status --profile work
```

## Resources

- Read [the README](https://github.com/rohithzr/claudebase#readme) for installation, shared layers, and supported configuration paths.
- Read [the privacy policy](https://github.com/rohithzr/claudebase/blob/main/PRIVACY.md) for backup storage and credential handling.
- Read [the changelog](https://github.com/rohithzr/claudebase/blob/main/CHANGELOG.md) for changes affecting installed versions.

## User Arguments

Interpret the following input as arguments for the documented operation:

$ARGUMENTS
