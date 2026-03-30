# Contributing to Claudebase

Thanks for your interest in contributing! This guide covers everything you need to get started.

## Getting Started

```bash
git clone https://github.com/rohithzr/claudebase.git
cd claudebase
git submodule update --init --recursive
```

### Running locally

Load the plugin from your checkout:

```bash
claude --plugin-dir ./
```

### Dependencies

- `bash` — all scripts target bash
- `gh` CLI (authenticated) — GitHub operations
- `git` — version control
- `jq` — JSON manipulation
- [BATS](https://github.com/bats-core/bats-core) — test framework (included as submodule)

## Project Structure

```
scripts/          # Core logic (common.sh, sync-push.sh, sync-pull.sh, etc.)
skills/           # SKILL.md files for each slash command
hooks/            # Lifecycle hooks + cross-platform wrapper
tests/            # BATS test suites + helpers + fixtures
.claude-plugin/   # Plugin and marketplace manifests
```

### Scripts

All scripts source `scripts/common.sh` for shared utilities (colors, state management, `gh` helpers, secret scanning). State is stored as JSON in `state.json`, manipulated via `jq`.

### Skills

Each skill lives in `skills/<name>/SKILL.md`. Key conventions:
- `description` in frontmatter must be a trigger condition starting with "Use when..."
- Frontmatter max 1024 chars total
- Name format: lowercase, hyphens only, verb-first preferred

## Running Tests

```bash
# All 158 tests
./tests/bats/bin/bats tests/

# By suite
./tests/bats/bin/bats tests/unit/          # 57 unit tests
./tests/bats/bin/bats tests/integration/   # 72 integration tests
./tests/bats/bin/bats tests/e2e/           # 29 E2E tests
```

### Test architecture

- **Unit** — individual functions from `common.sh` and `config-manager.sh`, mocked `gh`
- **Integration** — each script end-to-end with real `git` and local bare repos (no GitHub needed)
- **E2E** — simulates 2-3 machines with isolated environments, tests conflict detection and full workflows

CI runs on every push across macOS, Linux, and Windows.

## Submitting Changes

1. Fork the repo and create a branch from `main`
2. Make your changes
3. Add or update tests if applicable
4. Run the full test suite and make sure it passes
5. Open a pull request

### Pull request guidelines

- Keep PRs focused — one feature or fix per PR
- Include a clear description of what changed and why
- If adding a new feature, include test coverage
- If fixing a bug, include a test that reproduces it

### Commit messages

- Use present tense ("Add feature" not "Added feature")
- Keep the first line under 72 characters
- Reference issues when relevant (`Fixes #123`)

## Reporting Bugs

Open a [bug report](https://github.com/rohithzr/claudebase/issues/new?template=bug_report.md) with:
- Steps to reproduce
- Expected vs actual behavior
- Platform (macOS, Linux, Windows) and shell

## Suggesting Features

Open a [feature request](https://github.com/rohithzr/claudebase/issues/new?template=feature_request.md). Describe the use case, not just the solution.

## Code of Conduct

This project follows the [Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/). Be respectful, constructive, and inclusive.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
