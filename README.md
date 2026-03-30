# Claudebase

Back up, restore, and sync your entire Claude Code environment across machines using a private GitHub repo. Profiles let you switch between configurations instantly.

## Requirements

[GitHub CLI (`gh`)](https://cli.github.com/) | [`jq`](https://jqlang.github.io/jq/) | [`git`](https://git-scm.com/) | `bash`

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

## Install

### From the terminal

```bash
claude plugin marketplace add rohithzr/claudebase
claude plugin install claudebase@rohithzr
```

### From within a running Claude Code session

```
/plugin marketplace add rohithzr/claudebase
/plugin install claudebase@rohithzr
```

After installing, restart Claude Code or run `/reload-plugins` to activate.

### Update

```bash
# Terminal
claude plugin update claudebase@rohithzr

# Or inside Claude Code
/plugin update claudebase
```

Skills update automatically when the plugin updates.

### Uninstall

```bash
# Terminal
claude plugin uninstall claudebase@rohithzr
claude plugin marketplace remove rohithzr

# Or inside Claude Code
/plugin uninstall claudebase
/plugin marketplace remove rohithzr
```

## Quick Start

```
/claudebase:setup                # One-time: create private GitHub repo + first push
/claudebase:push                 # Push current config to GitHub
/claudebase:pull                 # Pull config from GitHub
/claudebase:status               # Compare local vs remote
/claudebase:config               # View/change plugin settings
/claudebase:profiles list        # List all profiles
/claudebase:profiles create work # Create a new profile
/claudebase:profiles switch work # Switch active profile
```

## Examples

### First-time setup on a new machine

```
/claudebase:setup                            # Creates private repo, initializes profile
/claudebase:push                             # Backs up your current config
```

### Daily workflow — single machine

```
/claudebase:status                           # Check if anything changed
/claudebase:push                             # Save today's changes
```

### Syncing between two machines

```
Laptop:  /claudebase:push                    # Push your config
Desktop: /claudebase:pull                    # Pull it down

Desktop: # ... tweak agents, add rules ...

Desktop: /claudebase:push --force            # Push from second machine
Laptop:  /claudebase:pull                    # Get desktop's changes
```

### Setting up work and personal profiles

```
/claudebase:profiles create work             # New empty profile
/claudebase:profiles create personal         # Another one

# Push current config to work
/claudebase:profiles switch work
/claudebase:push

# Switch to personal, start fresh
/claudebase:profiles switch personal
# ... set up personal agents, rules ...
/claudebase:push
```

### Switching contexts during the day

```
/claudebase:profiles switch work             # Pull work config
# ... deep coding session ...

/claudebase:push                             # Save work state
/claudebase:profiles switch personal         # Switch to personal
# ... side project with different agents ...

/claudebase:push                             # Save personal state
```

### Onboarding a teammate

```
# You: push your team config to a shared profile
/claudebase:profiles create team-defaults --from work
/claudebase:push

# Teammate: on their machine
/claudebase:setup
/claudebase:pull --profile team-defaults     # Gets your agents, rules, skills
```

### Previewing before you commit

```
/claudebase:push --dry-run                   # See what would be pushed
/claudebase:pull --dry-run                   # See what would change locally
/claudebase:profiles diff work personal      # Compare two profiles
```

### Recovering after a bad change

```
# Oops, broke your config
/claudebase:pull                             # Restores from last push
                                             # Old config saved to backups/

# Backups are at ~/.claude/plugins/data/claudebase/backups/
```

### Three-machine round-robin

```
Laptop:   /claudebase:push                   # Push initial config

Desktop:  /claudebase:pull                   # Get laptop's config
Desktop:  # ... add new agents ...
Desktop:  /claudebase:push --force           # Push desktop's additions

CI Box:   /claudebase:pull                   # CI gets latest from desktop
CI Box:   # ... add CI-specific rules ...
CI Box:   /claudebase:push --force           # Push CI additions

Laptop:   /claudebase:pull                   # Laptop gets everything
```

## What it syncs

| Path | Description | Sync behavior |
|------|-------------|---------------|
| `.mcp.json` | MCP server configurations | Always |
| `.claude/settings.json` | Team-shared settings | Always |
| `.claude/agents/` | Subagent definitions | Always |
| `.claude/commands/` | Slash command templates | Always |
| `.claude/skills/` | Reusable knowledge modules | Always |
| `.claude/hooks/` | Lifecycle hooks (scripts, config, sounds) | Always |
| `.claude/rules/` | Organization rules | Always |
| `.claude/agent-memory/` | Persistent agent memory | Always |
| `.auto-memory/` | Auto-memory files | Always |
| `skills-lock.json` | Vercel/agentskills.io lock file | Opt-in (`/claudebase:config set sync_agent_skills true`) |
| `~/.claude/settings.json` | Global user settings | Opt-in (`--include-global` flag) |

**Never synced:** `settings.local.json`, `hooks-config.local.json`, conversations, sessions, shell snapshots, `.jsonl` logs.

## How it works

```
           ┌─────────────┐
Machine A  │ .claude/     │──push──┐
           │ .mcp.json    │        │     ┌──────────────────────┐
           │ .auto-memory/│        ├────>│  GitHub (private)    │
           └─────────────┘        │     │  profiles/default/   │
                                  │     │  profiles/work/      │
           ┌─────────────┐        │     │  shared/             │
Machine B  │ .claude/     │<─pull──┘     │  global/             │
           │ .mcp.json    │              └──────────────────────┘
           │ .auto-memory/│
           └─────────────┘
```

1. **Setup** (`/claudebase:setup`) — creates a private GitHub repo, initializes a profile structure, performs first push
2. **Push** (`/claudebase:push`) — collects local config files, scans for secrets, commits to `profiles/<name>/` in the repo
3. **Pull** (`/claudebase:pull`) — fetches from repo, creates a backup, applies shared config first then profile overlay
4. **Status** (`/claudebase:status`) — diffs local vs remote, shows modified/local-only/remote-only files
5. **Profiles** (`/claudebase:profiles`) — create, delete, switch, diff, and inspect named configurations
6. **Config** (`/claudebase:config`) — view and modify plugin settings (auto-push, global sync, machine ID)

### Profile structure in the GitHub repo

```
claude-config/
├── profiles/
│   ├── default/          # Your default setup
│   ├── work/             # Work-specific config
│   └── personal/         # Personal config
├── shared/               # Applied to ALL profiles (base layer)
│   ├── skills/           # Team-wide skills
│   ├── rules/            # Organization rules
│   └── agents/           # Shared agents
├── global/               # User-level ~/.claude/ settings
└── .sync-meta.json       # Sync metadata (machines, timestamps)
```

When you pull, **shared/** is applied first as a base layer, then **profiles/\<name\>/** overlays on top. This lets you maintain organization-wide defaults while customizing per context.

### Multi-machine workflow

```
Laptop:  /claudebase:push                    # Push your config
Desktop: /claudebase:pull                    # Pull it down
Desktop: # ... make changes ...
Desktop: /claudebase:push --force            # Push from second machine
Laptop:  /claudebase:pull                    # Get desktop's changes
```

Claudebase tracks which machine last pushed each profile. If a different machine pushed since your last sync, push is blocked with a warning — pull first or use `--force` to override.

### Profile switching

```
/claudebase:profiles create work             # Create from scratch
/claudebase:profiles create staging --from work  # Clone existing
/claudebase:push                             # Push to current profile
/claudebase:profiles switch personal         # Switch + pull
/claudebase:profiles diff work personal      # Compare two profiles
/claudebase:profiles delete staging          # Remove a profile
```

## Safety

| Protection | Description |
|-----------|-------------|
| **Backup before pull** | Every pull creates a timestamped backup. Last 10 are kept. |
| **Confirmation prompt** | Pull shows a diff preview and asks before overwriting. Use `--yes` to skip. |
| **Secret scanning** | Warns on API keys (OpenAI, GitHub, AWS), PEM keys, Bearer tokens. Use `--force` to override. |
| **Multi-machine detection** | Blocks push if another machine pushed since your last sync. |
| **Private repo** | GitHub repo is created as private by default. |
| **Dry run** | `--dry-run` on push/pull shows what would change without doing it. |
| **Global opt-in** | `~/.claude/settings.json` is never synced unless you explicitly pass `--include-global`. |
| **Never-sync list** | Conversations, sessions, shell snapshots, and logs are excluded by design. |

## Configuration

```
/claudebase:config show                      # View all settings
/claudebase:config set auto_push true        # Auto-push on session end
/claudebase:config set include_global true   # Always sync global settings
/claudebase:config set sync_agent_skills true # Sync Vercel skills lock file
/claudebase:config set machine_id my-laptop  # Custom machine identifier
/claudebase:config reset auto_push           # Reset to default
```

### Hooks

Claudebase registers two lifecycle hooks:

- **SessionStart** — runs a quiet diff check to see if your config is out of sync
- **SessionEnd** — auto-pushes changes if `auto_push` is enabled (skips on conflicts)

### Local manifest override

Create `.sync-manifest.local.json` in the plugin root to customize sync scope without modifying the base manifest. Arrays are fully replaced; objects are deep-merged.

## Data storage

```
~/.claude/plugins/data/claudebase/
├── repo/          # Shallow clone of your GitHub config repo
├── state.json     # Plugin state (profile, machine ID, timestamps)
└── backups/       # Timestamped backups from pulls (last 10)
```

## Authentication

Claudebase uses `gh` CLI for all GitHub operations — no tokens to manage, no OAuth flows, no credentials stored. If `gh auth status` passes, the plugin works.

## Philosophy

Your Claude Code setup is infrastructure. Agents, skills, rules, hooks, memory — these accumulate over weeks of work and represent real investment. Losing them to a disk wipe, or manually recreating them on a new machine, shouldn't happen.

Claudebase treats your config like code: versioned, portable, and recoverable. Profiles make context-switching instant instead of manual. The shared layer lets teams distribute defaults without overwriting individual setups.

The design is deliberately conservative — private repos, secret scanning, confirmation prompts, automatic backups — because overwriting someone's config is worse than making them type `--yes`.

## Contributing

Contributions are welcome. The codebase is bash scripts with BATS tests.

### Setup

```bash
git clone https://github.com/rohithzr/claudebase.git
cd claudebase
git submodule update --init --recursive   # BATS test framework
```

### Running tests

```bash
# All tests (158 total)
./tests/bats/bin/bats tests/unit/ tests/integration/ tests/e2e/

# By suite
./tests/bats/bin/bats tests/unit/          # 57 unit tests
./tests/bats/bin/bats tests/integration/   # 72 integration tests
./tests/bats/bin/bats tests/e2e/           # 29 E2E tests (multi-machine sim)
```

### Test architecture

- **Unit** — tests individual functions from `common.sh` and `config-manager.sh` with mocked `gh`
- **Integration** — tests each script end-to-end with real `git` and local bare repos (no GitHub)
- **E2E** — simulates 2-3 machines with isolated environments, tests conflict detection, profile workflows, and full push/pull cycles

CI runs on every push: macOS + Linux (required) and Windows (non-blocking).

### Project structure

```
scripts/          # Core logic (common.sh, sync-push.sh, sync-pull.sh, etc.)
skills/           # SKILL.md files for each slash command
hooks/            # Lifecycle hooks + cross-platform wrapper
tests/            # BATS test suites + helpers + fixtures
.claude-plugin/   # Plugin and marketplace manifests
```

### Local development

```bash
# Run Claude Code with the plugin loaded from your local checkout
claude --plugin-dir ./
```

## License

MIT
