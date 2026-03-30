# Claudebase

A Claude Code plugin that backs up and restores your complete Claude Code environment to a private GitHub repository.

## Requirements

- [GitHub CLI (`gh`)](https://cli.github.com/) — authenticated (`gh auth login`)
- [`jq`](https://jqlang.github.io/jq/) — JSON processor
- [`git`](https://git-scm.com/) — version control
- `bash` — shell (included on macOS/Linux; via Git Bash on Windows)

<details>
<summary>Installation instructions (macOS / Linux / Windows)</summary>

### macOS

```bash
brew install gh jq git
gh auth login
```

### Linux (Debian/Ubuntu)

```bash
# GitHub CLI
(type -p wget >/dev/null || sudo apt-get install wget -y) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

# jq and git
sudo apt-get install -y jq git

gh auth login
```

### Windows

Install [Git for Windows](https://git-scm.com/download/win) (includes Git Bash), then in PowerShell:

```powershell
winget install GitHub.cli
winget install jqlang.jq
gh auth login
```

</details>

## Installation

```bash
# Step 1: Add the marketplace
claude plugin marketplace add rohithzr/claudebase

# Step 2: Install the plugin
claude plugin install claudebase@rohithzr
```

## Quick Start

```
/claudebase:setup                # One-time: create repo + first push
/claudebase:push                 # Push current config to GitHub
/claudebase:pull                 # Pull config from GitHub
/claudebase:status               # Compare local vs remote
/claudebase:config               # View/change sync settings
/claudebase:profiles list        # List all profiles
/claudebase:profiles create work # Create a new profile
/claudebase:profiles switch work # Switch to a different profile
```

## What it syncs

- `.mcp.json` — MCP server configurations
- `.claude/settings.json` — team-shared settings
- `.claude/agents/` — subagent definitions
- `.claude/commands/` — slash command templates
- `.claude/skills/` — reusable knowledge modules
- `.claude/hooks/` — lifecycle hooks (scripts, config, sounds)
- `.claude/rules/` — organization rules
- `.claude/agent-memory/` — persistent agent memory
- `.auto-memory/` — auto-memory files
- `~/.claude/settings.json` — global user settings (opt-in via `--include-global`)

Machine-specific files (`settings.local.json`, `hooks-config.local.json`, conversations, sessions) are **never** synced.

## How it works

1. **Setup** creates a private GitHub repo and initializes it with a profile structure
2. **Push** collects your local Claude Code config files and commits them to the repo under `profiles/<name>/`
3. **Pull** fetches from the repo, backs up your current config, and applies the profile
4. **Profiles** let you maintain multiple configurations (e.g., work, personal, project-specific)

### Profile structure in the GitHub repo

```
claude-config/
├── profiles/
│   ├── default/          # Your default setup
│   ├── work/             # Work-specific config
│   └── personal/         # Personal config
├── shared/               # Files applied to ALL profiles
└── global/               # User-level settings (~/.claude/)
```

### Safety features

- **Confirmation before pull** — shows what will change and prompts before overwriting (`--yes` to skip)
- **Backup before pull** — every pull creates a timestamped backup (keeps last 10)
- **Secret scanning** — warns if config files contain API keys or tokens
- **Multi-machine protection** — warns if another machine pushed since your last sync
- **Private by default** — GitHub repo is created as private
- **Dry run** — `--dry-run` flag on push/pull shows what would change
- **Global settings opt-in** — `~/.claude/settings.json` only syncs with `--include-global`

## Data storage

Claudebase keeps a shallow clone of your config repo locally at:

```
~/.claude/plugins/data/claudebase/repo/
```

Other local data (state, backups) lives under `~/.claude/plugins/data/claudebase/`. Backups are pruned to the last 10 automatically.

## Authentication

Uses `gh` CLI — no tokens to manage. If `gh` is authenticated, the plugin works. Run `gh auth login` if needed.

## License

MIT
