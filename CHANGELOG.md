# Changelog

All notable changes to Claudebase will be documented in this file.

## [0.2.2] - 2026-09-30

### Fixed
- The `SessionEnd` hook now honors `auto_push`. `sync-push.sh --auto` previously ignored the setting and pushed on every session end once setup was complete, even though `auto_push` defaults to `false`.
- `sync-push --dry-run` no longer copies files into the local repo working tree. The copy ran before the dry-run check, so leftovers from a dry-run were silently committed by the next real push, including a push to a different profile. Dry-run now compares each source against the repo copy and reports `Would sync` or `Unchanged` per item, still runs the secret scan, and exits before touching git.

### Added
- Plugin icon (`assets/icon.svg`), referenced from `plugin.json`.

### Changed
- Removed the git submodules for BATS and its unused helper libraries. The plugin now ships only readable source; contributors and CI clone `bats-core` v1.13.0 into `tests/bats/`.
- README links to GitHub's official `gh` install instructions for Linux instead of inlining the download commands.

### Tests
- Added `dry-run leaves the repo working tree untouched` and `dry-run reports unchanged items after a real push` to `tests/integration/sync_push.bats`.
- Added `auto mode does not push when auto_push is off` and `auto mode pushes when auto_push is enabled`.

## [0.2.1] - 2026-04-12

### Fixed
- `claudebase:sync-setup` no longer silently proceeds when the initial `gh repo clone` fails (SSH hostkey, expired auth, network). The script now distinguishes a genuinely empty remote from a real clone failure using `gh repo view --json isEmpty`, surfaces stderr on failure, and exits with an actionable hint instead of falling through to a half-initialized local repo.
- `setup_complete=true` is now written to `state.json` only after the initial push succeeds, so a failed push can no longer leave the sync state looking ready when it isn't.
- Remote URLs now honor `gh`'s configured git protocol (`ssh` or `https`) via a new `get_remote_url` helper, replacing hard-coded HTTPS URLs that broke `git pull`/`git push` for users with SSH-configured gh.

### Changed
- Clone-failure error message broadened to cover SSH hostkey, expired auth, network, and permissions, each paired with a concrete recovery command.

### Tests
- Added `tests/unit/common_remote_url.bats` covering both the ssh and https branches of `get_remote_url`, plus the dashed-owner and unset-protocol edge cases.
- Split the stale `handles empty repo clone failure gracefully` integration test into two: one that verifies the empty-remote init path pushes correctly via a `url.insteadOf` redirect, and one that verifies a real clone failure exits nonzero with the helpful hint and leaves `setup_complete` unset.
- Extended `tests/test_helper/mock_gh.bash` with `MOCK_GH_REPO_EMPTY`, `MOCK_GH_CLONE_FAILS`, and `MOCK_GH_PROTOCOL` env vars so the mock can simulate empty repos, clone failures, and configured git protocols. Also fixed a latent bug where `local` at top-level script scope silently failed on every mock invocation.

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
