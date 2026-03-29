# Claudebase

A Claude Code plugin that backs up and restores your complete Claude Code environment to a private GitHub repository.

## What it syncs

- `CLAUDE.md` — project instructions
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

## Requirements

- [GitHub CLI (`gh`)](https://cli.github.com/) installed and authenticated
- `git`, `jq`, `bash`

## Installation

```bash
# Test locally during development
claude --plugin-dir ./claudebase

# Or add to your Claude Code settings
```

## Quick Start

```
/cb:setup                    # One-time: create repo + first push
/cb:push                     # Push current config to GitHub
/cb:pull                     # Pull config from GitHub
/cb:status                   # Compare local vs remote
/cb:profiles list            # List all profiles
/cb:profiles create work     # Create a new profile
/cb:profiles switch work     # Switch to a different profile
```

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
