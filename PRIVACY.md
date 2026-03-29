# Privacy Policy

**Claudebase** does not collect, store, or transmit any personal data or telemetry.

## How your data is handled

- All configuration files are stored in **your own private GitHub repository**, created and owned by your GitHub account.
- Data transfer occurs exclusively between your local machine and your GitHub repository via the authenticated `gh` CLI.
- No data is sent to the plugin author, Anthropic, or any third-party service.
- No analytics, tracking, or usage metrics are collected.

## What is stored locally

- A shallow git clone of your backup repo at `~/.claude/plugins/data/claudebase/repo/`
- A state file (`state.json`) tracking your active profile and last sync timestamp
- Temporary backups before pull operations at `~/.claude/plugins/data/claudebase/backups/`

All local data can be removed by deleting the `~/.claude/plugins/data/claudebase/` directory.

## Secret scanning

The plugin includes built-in secret detection that warns you before pushing files containing potential API keys, tokens, or credentials. This scanning happens entirely on your local machine.

## Contact

If you have questions about this policy, please open an issue on the [GitHub repository](https://github.com/rohithazra/claude-config-sync).
