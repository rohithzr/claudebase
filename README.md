# Claudebase

[![CI](https://github.com/rohithzr/claudebase/actions/workflows/test.yml/badge.svg)](https://github.com/rohithzr/claudebase/actions/workflows/test.yml)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-0.1.0-green.svg)](CHANGELOG.md)

Your Claude Code setup is infrastructure. Agents, skills, rules, hooks, memory — these accumulate over weeks of work and represent real investment. Losing them to a disk wipe, or manually recreating them on a new machine, shouldn't happen.

**Claudebase syncs your entire Claude Code environment to a private GitHub repo.** Profiles let you switch between work, personal, and team configurations instantly. Secret scanning, automatic backups, and multi-machine conflict detection keep things safe.

<!-- TODO: Add asciinema demo GIF here -->
<!-- [![demo](docs/demo.gif)](#quick-start) -->

## Install

```bash
claude plugin marketplace add rohithzr/claudebase
claude plugin install claudebase@rohithzr
```

Then restart Claude Code or run `/reload-plugins`.

<details>
<summary>Update / Uninstall</summary>

```bash
# Update
claude plugin update claudebase@rohithzr

# Uninstall
claude plugin uninstall claudebase@rohithzr
claude plugin marketplace remove rohithzr
```
</details>

## Quick Start

```
/claudebase:setup          # One-time: create private GitHub repo + first push
/claudebase:push           # Back up current config
/claudebase:pull           # Restore config from GitHub
/claudebase:status         # Compare local vs remote
/claudebase:profiles list  # Manage named profiles
/claudebase:config         # View/change settings
```

## Why Not Just Copy the Folder?

| | Manual copy | Claudebase |
|---|---|---|
| Secret scanning | No | Blocks API keys, PEM files, tokens |
| Multi-machine safety | No | Detects conflicting pushes |
| Profiles | No | Switch work/personal/team instantly |
| Shared team layer | No | Base config + per-person overlay |
| Automatic backups | No | Timestamped backup before every pull |
| Dry run preview | No | See what changes before committing |

## Examples

### Sync between machines

```
Laptop:  /claudebase:push               # Push your config
Desktop: /claudebase:pull               # Pull it down
Desktop: # ... tweak agents, add rules ...
Desktop: /claudebase:push --force       # Push from second machine
Laptop:  /claudebase:pull               # Get desktop's changes
```

### Switch contexts during the day

```
/claudebase:profiles switch work        # Load work config
# ... deep coding session ...
/claudebase:push                        # Save work state
/claudebase:profiles switch personal    # Load personal config
```

### Preview before committing

```
/claudebase:push --dry-run              # See what would be pushed
/claudebase:pull --dry-run              # See what would change locally
/claudebase:profiles diff work personal # Compare two profiles
```

<details>
<summary>More examples</summary>

### Onboard a teammate

```
# You: push your team config to a shared profile
/claudebase:profiles create team-defaults --from work
/claudebase:push

# Teammate: on their machine
/claudebase:setup
/claudebase:pull --profile team-defaults
```

### Recover from a bad change

```
/claudebase:pull                        # Restores from last push
                                        # Old config saved to backups/
```

### Three-machine round-robin

```
Laptop:   /claudebase:push
Desktop:  /claudebase:pull && /claudebase:push --force
CI Box:   /claudebase:pull && /claudebase:push --force
Laptop:   /claudebase:pull              # Gets everything
```
</details>

## What Gets Synced

| Path | Description |
|------|-------------|
| `.mcp.json` | MCP server configurations |
| `.claude/settings.json` | Team-shared settings |
| `.claude/agents/` | Subagent definitions |
| `.claude/commands/` | Slash command templates |
| `.claude/skills/` | Reusable knowledge modules |
| `.claude/hooks/` | Lifecycle hooks |
| `.claude/rules/` | Organization rules |
| `.claude/agent-memory/` | Persistent agent memory |
| `.auto-memory/` | Auto-memory files |

**Opt-in:** Global `~/.claude/settings.json` (`--include-global`), Vercel skills lock (`/claudebase:config set sync_agent_skills true`).

**Never synced:** `settings.local.json`, conversations, sessions, shell snapshots, logs.

## How It Works

```
           ┌──────────────┐
Machine A  │ .claude/     │──push──┐
           │ .mcp.json    │        │     ┌──────────────────────┐
           │ .auto-memory/│        ├────>│  GitHub (private)    │
           └──────────────┘        │     │  profiles/default/   │
                                   │     │  profiles/work/      │
           ┌──────────────┐        │     │  shared/             │
Machine B  │ .claude/     │<─pull──┘     └──────────────────────┘
           │ .mcp.json    │
           │ .auto-memory/│
           └──────────────┘
```

When you pull, **shared/** is applied first as a base layer, then **profiles/\<name\>/** overlays on top. This lets you maintain organization-wide defaults while customizing per context.

Push is blocked if a different machine pushed since your last sync — pull first or use `--force` to override.

## Safety

| Protection | How it works |
|-----------|-------------|
| Backup before pull | Every pull creates a timestamped backup (last 10 kept) |
| Confirmation prompt | Pull shows a diff and asks before overwriting (`--yes` to skip) |
| Secret scanning | Blocks API keys, PEM keys, Bearer tokens (`--force` to override) |
| Multi-machine detection | Blocks push if another machine pushed since your last sync |
| Private repo | Created private by default |
| Dry run | `--dry-run` on push/pull shows changes without applying |
| Never-sync list | Conversations, sessions, logs excluded by design |

## Configuration

```
/claudebase:config show                      # View all settings
/claudebase:config set auto_push true        # Auto-push on session end
/claudebase:config set include_global true   # Always sync global settings
/claudebase:config set machine_id my-laptop  # Custom machine identifier
/claudebase:config reset auto_push           # Reset to default
```

Claudebase also registers two lifecycle hooks:
- **SessionStart** — quiet diff check (tells you if config is out of sync)
- **SessionEnd** — auto-pushes if `auto_push` is enabled

## Requirements

[GitHub CLI (`gh`)](https://cli.github.com/) | [`jq`](https://jqlang.github.io/jq/) | [`git`](https://git-scm.com/) | `bash`

Claudebase uses `gh` for all GitHub operations — no tokens to manage, no OAuth, no stored credentials.

<details>
<summary>Platform-specific install instructions</summary>

**macOS**
```bash
brew install gh jq git
gh auth login
```

**Linux (Debian/Ubuntu)**
```bash
# GitHub CLI (https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
(type -p wget >/dev/null || sudo apt-get install wget -y) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

sudo apt-get install -y jq git
gh auth login
```

**Windows** — Install [Git for Windows](https://git-scm.com/download/win) (includes Git Bash), then:
```powershell
winget install GitHub.cli
winget install jqlang.jq
gh auth login
```
</details>

## Contributing

Contributions welcome. See the [Code of Conduct](CODE_OF_CONDUCT.md).

```bash
git clone https://github.com/rohithzr/claudebase.git
cd claudebase
git submodule update --init --recursive
```

### Running tests

```bash
./tests/bats/bin/bats tests/                 # All 158 tests
./tests/bats/bin/bats tests/unit/            # 57 unit tests
./tests/bats/bin/bats tests/integration/     # 72 integration tests
./tests/bats/bin/bats tests/e2e/             # 29 E2E tests
```

CI runs on every push across macOS, Linux, and Windows.

### Local development

```bash
claude --plugin-dir ./
```

## License

[MIT](LICENSE)
