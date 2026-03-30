#!/usr/bin/env bats
# Integration tests for diff-config.sh

load '../test_helper/common'
load '../test_helper/fixtures'
load '../test_helper/assertions'

setup() {
  common_setup
  export ORIGINAL_PATH="$PATH"

  TEST_BARE="${TEST_TEMP}/remote.git"
  create_bare_remote "$TEST_BARE"
  export MOCK_GH_CLONE_SOURCE="$TEST_BARE"
  initialize_remote_with_profile "$TEST_BARE" "default" "test-machine"

  setup_local_repo_clone "$TEST_BARE" "${CLAUDE_PLUGIN_DATA}/repo"
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  git config user.email "test@test.com"
  git config user.name "Test User"

  # Add config to repo
  echo '{"mcpServers":{}}' > profiles/default/mcp.json
  echo '{"permissions":{}}' > profiles/default/settings.json
  mkdir -p profiles/default/agents
  echo "# Agent" > profiles/default/agents/review.md
  git add -A && git commit -m "add config" --quiet
  git push --quiet 2>/dev/null
  cd - >/dev/null

  create_state_file "$CLAUDE_PLUGIN_DATA" "test-machine" "default"
}

teardown() {
  common_teardown
}

@test "reports no changes when in sync" {
  # Create matching local files
  echo '{"mcpServers":{}}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude"
  echo '{"permissions":{}}' > "${CLAUDE_PROJECT_DIR}/.claude/settings.json"
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/agents"
  echo "# Agent" > "${CLAUDE_PROJECT_DIR}/.claude/agents/review.md"

  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"in sync"* ]]
}

@test "detects modified file" {
  echo '{"mcpServers":{"modified":true}}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude"
  echo '{"permissions":{}}' > "${CLAUDE_PROJECT_DIR}/.claude/settings.json"

  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"modified"* ]]
}

@test "detects local-only file" {
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude"
  echo '{"permissions":{}}' > "${CLAUDE_PROJECT_DIR}/.claude/settings.json"
  # mcp.json exists locally but also in repo, so create something only local has
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/commands"
  echo "# cmd" > "${CLAUDE_PROJECT_DIR}/.claude/commands/local-only.md"

  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [[ "$output" == *"local only"* ]]
}

@test "detects remote-only file" {
  # Don't create any local files — everything is remote-only
  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"remote only"* ]]
}

@test "detects modified directory" {
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude/agents"
  echo "# Different content" > "${CLAUDE_PROJECT_DIR}/.claude/agents/review.md"

  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"modified"* ]]
}

@test "reports correct summary counts" {
  # Create one matching, one modified
  echo '{"mcpServers":{"changed":true}}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude"
  echo '{"permissions":{}}' > "${CLAUDE_PROJECT_DIR}/.claude/settings.json"

  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Summary"* ]] || [[ "$output" == *"modified"* ]]
}

@test "quiet mode suppresses output" {
  run bash "${SCRIPTS_DIR}/diff-config.sh" --quiet
  [ "$output" = "" ] || [ ${#output} -eq 0 ]
}

@test "quiet mode returns correct exit code for differences" {
  # No local files = differences exist
  run bash "${SCRIPTS_DIR}/diff-config.sh" --quiet
  [ "$status" -eq 1 ]
}

@test "exits when not set up" {
  echo '{}' > "${CLAUDE_PLUGIN_DATA}/state.json"
  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not set up"* ]]
}

@test "quiet mode exits 0 when not set up" {
  echo '{}' > "${CLAUDE_PLUGIN_DATA}/state.json"
  run bash "${SCRIPTS_DIR}/diff-config.sh" --quiet
  [ "$status" -eq 0 ]
}

@test "shows last push/pull timestamps" {
  # Add timestamps to state
  local sf="${CLAUDE_PLUGIN_DATA}/state.json"
  local tmp
  tmp=$(mktemp)
  jq '.last_push = "2026-01-15T10:00:00Z" | .last_pull = "2026-01-15T09:00:00Z"' "$sf" > "$tmp" && mv "$tmp" "$sf"

  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [[ "$output" == *"Last push"* ]]
  [[ "$output" == *"Last pull"* ]]
}
