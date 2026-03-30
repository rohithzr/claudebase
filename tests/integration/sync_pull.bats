#!/usr/bin/env bats
# Integration tests for sync-pull.sh

load '../test_helper/common'
load '../test_helper/fixtures'
load '../test_helper/assertions'

setup() {
  common_setup
  export ORIGINAL_PATH="$PATH"

  # Create bare remote and initialize
  TEST_BARE="${TEST_TEMP}/remote.git"
  create_bare_remote "$TEST_BARE"
  export MOCK_GH_CLONE_SOURCE="$TEST_BARE"
  initialize_remote_with_profile "$TEST_BARE" "default" "test-machine"

  # Clone into plugin data
  setup_local_repo_clone "$TEST_BARE" "${CLAUDE_PLUGIN_DATA}/repo"
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  git config user.email "test@test.com"
  git config user.name "Test User"

  # Add some config files to the repo profile
  mkdir -p profiles/default/agents profiles/default/commands profiles/default/rules
  echo '{"mcpServers":{"remote":true}}' > profiles/default/mcp.json
  echo '{"permissions":{"allow":["Read"]}}' > profiles/default/settings.json
  echo "# Remote agent" > profiles/default/agents/remote.md
  echo "# Remote command" > profiles/default/commands/remote-cmd.md
  echo "# Remote rule" > profiles/default/rules/remote-rule.md
  git add -A && git commit -m "Add config files" --quiet
  git push --quiet 2>/dev/null
  cd - >/dev/null

  # Create state file
  create_state_file "$CLAUDE_PLUGIN_DATA" "test-machine" "default"
}

teardown() {
  common_teardown
}

@test "pulls and applies config files to project" {
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  [ -f "${CLAUDE_PROJECT_DIR}/.mcp.json" ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/settings.json" ]
  run cat "${CLAUDE_PROJECT_DIR}/.mcp.json"
  [[ "$output" == *"remote"* ]]
}

@test "pulls all directory types" {
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  [ -f "${CLAUDE_PROJECT_DIR}/.claude/agents/remote.md" ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/commands/remote-cmd.md" ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/rules/remote-rule.md" ]
}

@test "creates backup before applying" {
  # Create existing local config so there's something to backup
  create_sample_project "$CLAUDE_PROJECT_DIR"

  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  assert_backup_exists "${CLAUDE_PLUGIN_DATA}/backups"
}

@test "backup contains original files" {
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude"
  echo '{"original":true}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"

  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  # Find the backup directory
  local backup_dir
  backup_dir=$(ls -d "${CLAUDE_PLUGIN_DATA}/backups"/backup-* | head -1)
  [ -f "${backup_dir}/.mcp.json" ]
  run cat "${backup_dir}/.mcp.json"
  [[ "$output" == *"original"* ]]
}

@test "backup cleanup keeps only last 10" {
  # Create 12 fake old backups
  for i in $(seq 1 12); do
    mkdir -p "${CLAUDE_PLUGIN_DATA}/backups/backup-20260101-00000${i}"
    echo "old" > "${CLAUDE_PLUGIN_DATA}/backups/backup-20260101-00000${i}/marker"
  done

  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  local count
  count=$(ls -d "${CLAUDE_PLUGIN_DATA}/backups"/backup-* | wc -l | tr -d ' ')
  [ "$count" -le 10 ]
}

@test "dry-run shows changes without applying" {
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]] || [[ "$output" == *"Dry run"* ]]

  # Local files should NOT exist
  [ ! -f "${CLAUDE_PROJECT_DIR}/.mcp.json" ]
}

@test "no-backup skips backup creation" {
  create_sample_project "$CLAUDE_PROJECT_DIR"

  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes --no-backup
  [ "$status" -eq 0 ]

  local count
  count=$(ls -d "${CLAUDE_PLUGIN_DATA}/backups"/backup-* 2>/dev/null | wc -l | tr -d ' ')
  [ "$count" -eq 0 ]
}

@test "exits when profile does not exist" {
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --profile nonexistent --yes
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "exits when not set up" {
  echo '{}' > "${CLAUDE_PLUGIN_DATA}/state.json"
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 1 ]
  [[ "$output" == *"not set up"* ]]
}

@test "applies shared config as base layer" {
  # Add shared skills
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  mkdir -p shared/skills
  echo "# Shared skill" > shared/skills/team-skill.md
  git add -A && git commit -m "add shared" --quiet
  git push --quiet 2>/dev/null
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/skills/team-skill.md" ]
}

@test "profile config overlays on shared" {
  # Add shared and profile agents with same name
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  mkdir -p shared/agents profiles/default/agents
  echo "# Shared version" > shared/agents/review.md
  echo "# Profile version" > profiles/default/agents/review.md
  git add -A && git commit -m "add overlap" --quiet
  git push --quiet 2>/dev/null
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  # Profile should win
  run cat "${CLAUDE_PROJECT_DIR}/.claude/agents/review.md"
  [[ "$output" == *"Profile version"* ]]
}

@test "validates JSON after apply" {
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]
  # Valid JSON — no warnings
  [[ "$output" != *"malformed"* ]]
}

@test "warns on malformed JSON after apply" {
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  echo '{bad json' > profiles/default/settings.json
  git add -A && git commit -m "break json" --quiet
  git push --quiet 2>/dev/null
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]
  [[ "$output" == *"malformed"* ]]
}

@test "updates metadata after pull" {
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  local meta="${CLAUDE_PLUGIN_DATA}/repo/.sync-meta.json"
  run jq -r '.profiles.default.last_pull' "$meta"
  [ "$output" != "null" ]
}

@test "updates state with last_pull timestamp" {
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  run jq -r '.last_pull' "${CLAUDE_PLUGIN_DATA}/state.json"
  [ "$output" != "null" ]
  [ "$output" != "" ]

  run jq -r '.active_profile' "${CLAUDE_PLUGIN_DATA}/state.json"
  [ "$output" = "default" ]
}

@test "yes flag skips confirmation prompt" {
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]
  # Should not contain any prompt text
  [[ "$output" != *"Proceed?"* ]]
}

@test "include-global applies global settings" {
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  mkdir -p global
  echo '{"global_setting": true}' > global/settings.json
  git add -A && git commit -m "add global" --quiet
  git push --quiet 2>/dev/null
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes --include-global
  [ "$status" -eq 0 ]
  [ -f "${HOME}/.claude/settings.json" ]
  run cat "${HOME}/.claude/settings.json"
  [[ "$output" == *"global_setting"* ]]
}
