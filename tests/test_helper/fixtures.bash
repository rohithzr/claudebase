#!/usr/bin/env bash
# fixtures.bash — Helper functions for creating test data

# Create a full sample project with all synced file types
create_sample_project() {
  local dir="$1"
  mkdir -p "${dir}/.claude/agents" "${dir}/.claude/commands" "${dir}/.claude/skills"
  mkdir -p "${dir}/.claude/hooks/scripts" "${dir}/.claude/hooks/config" "${dir}/.claude/hooks/sounds"
  mkdir -p "${dir}/.claude/rules" "${dir}/.claude/agent-memory" "${dir}/.auto-memory"

  echo '{"mcpServers":{}}' > "${dir}/.mcp.json"
  echo '{"permissions":{"allow":[]}}' > "${dir}/.claude/settings.json"
  echo "# Review agent" > "${dir}/.claude/agents/review.md"
  echo "# Custom command" > "${dir}/.claude/commands/deploy.md"
  echo "# My skill" > "${dir}/.claude/skills/my-skill.md"
  printf '#!/bin/bash\necho check' > "${dir}/.claude/hooks/scripts/pre-check.sh"
  echo '{"hooks":{}}' > "${dir}/.claude/hooks/config/hooks-config.json"
  echo "notification.wav" > "${dir}/.claude/hooks/sounds/alert.wav"
  echo "# Style rule" > "${dir}/.claude/rules/style.md"
  echo "Key context" > "${dir}/.claude/agent-memory/notes.md"
  echo "Auto memory entry" > "${dir}/.auto-memory/context.md"
}

# Create a state file with given params
create_state_file() {
  local dir="$1"
  local machine_id="${2:-test-machine}"
  local profile="${3:-default}"
  cat > "${dir}/state.json" <<EOF
{
  "setup_complete": "true",
  "repo_name": "claude-config",
  "repo_full": "testuser/claude-config",
  "active_profile": "${profile}",
  "machine_id": "${machine_id}",
  "setup_date": "2026-01-01T00:00:00Z"
}
EOF
}

# Create a local bare git repo to act as "remote"
create_bare_remote() {
  local path="$1"
  git init --bare "$path" --quiet
}

# Initialize a remote bare repo with profile structure
initialize_remote_with_profile() {
  local bare="$1"
  local profile="${2:-default}"
  local machine="${3:-test-machine}"
  local tmp
  tmp=$(mktemp -d)

  git clone "$bare" "${tmp}/repo" --quiet 2>/dev/null
  cd "${tmp}/repo"

  mkdir -p "profiles/${profile}/"{skills,agents,commands,hooks/scripts,hooks/config,hooks/sounds,rules,agent-memory,memory}
  mkdir -p shared/{skills,rules,agents} global

  cat > .sync-meta.json <<METAEOF
{
  "version": "1.0",
  "created": "2026-01-01T00:00:00Z",
  "profiles": {
    "${profile}": {
      "created": "2026-01-01T00:00:00Z",
      "last_push": null,
      "last_push_machine": null,
      "last_pull": null
    }
  },
  "machines": {
    "${machine}": {
      "first_seen": "2026-01-01T00:00:00Z",
      "last_seen": "2026-01-01T00:00:00Z"
    }
  }
}
METAEOF

  echo "# ${profile} profile" > "profiles/${profile}/README.md"
  echo "# Shared" > "shared/CLAUDE.md"

  cat > .gitignore <<'GIEOF'
settings.local.json
hooks-config.local.json
*.log
.DS_Store
GIEOF

  git add -A
  git commit -m "init" --quiet
  git branch -M main
  git push --quiet 2>/dev/null || true

  cd - >/dev/null
  rm -rf "$tmp"
}

# Clone the bare remote into a plugin data repo path (simulating ensure_local_repo)
setup_local_repo_clone() {
  local bare="$1"
  local repo_path="$2"
  git clone "$bare" "$repo_path" --quiet 2>/dev/null
}
