# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.2.x   | Yes       |
| < 0.2   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability in Claudebase, please report it privately rather than opening a public issue.

**How to report:**

1. Go to the [Security Advisories](https://github.com/rohithzr/claudebase/security/advisories) page
2. Click "Report a vulnerability"
3. Provide a description of the issue, steps to reproduce, and any relevant details

You can expect an initial response within 48 hours. We will work with you to understand the issue and coordinate a fix before any public disclosure.

## Scope

Security issues we care about:

- Secret scanning bypasses (patterns that should be caught but aren't)
- Credential or token leakage through sync operations
- Unintended file exfiltration (syncing files that should be excluded)
- Command injection via profile names, config values, or file paths
- Unauthorized access to the private GitHub repo

## Out of Scope

- Vulnerabilities in dependencies (`gh`, `jq`, `git`, `bash`) should be reported to their respective maintainers
- Issues requiring physical access to the machine
- Social engineering attacks

## Built-in Protections

Claudebase includes several security measures by design:

- **Secret scanning** blocks known API key patterns before push
- **Private repo** is enforced by default on setup
- **Never-sync list** excludes conversations, sessions, and logs
- **Local-only files** (`settings.local.json`) are never synced
- **Confirmation prompts** before overwriting local config on pull
