# Changelog

All notable changes to Claudebase will be documented in this file.

## [0.2.0] - 2026-04-01

### Changed
- Renamed skills to sync-prefixed names to avoid collisions with other plugins
  - `/push` → `/sync-push`, `/pull` → `/sync-pull`, `/setup` → `/sync-setup`
  - `/status` → `/sync-status`, `/profiles` → `/sync-profiles`, `/config` → `/sync-config`

## [0.1.0] - 2026-03-28

### Added
- Initial release as **claudebase** (renamed from config-sync)
- 5 skills: `/claudebase:setup`, `/claudebase:push`, `/claudebase:pull`, `/claudebase:status`, `/claudebase:profiles`
- Profile management: list, create, delete, info, switch, diff
- Shared config layer applied before profile overlay
- Secret scanning with configurable patterns
- Multi-machine push conflict detection
- Automatic backup before pull (keeps last 10)
- Confirmation prompt before pull overwrites (`--yes` to skip)
- Global settings sync opt-in (`--include-global`)
- Dry-run mode for push and pull
- Cross-platform hook wrapper (Unix + Windows/Git Bash)
- Manifest override via `.sync-manifest.local.json`
- SessionStart hook (diff check) and SessionEnd hook (auto-push)
- Shallow clone for local repo to minimize disk usage
- Marketplace manifest for plugin publishing
