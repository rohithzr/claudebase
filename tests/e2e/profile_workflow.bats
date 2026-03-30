#!/usr/bin/env bats
# E2E tests: profile lifecycle workflows

load '../test_helper/common'
load '../test_helper/fixtures'
load '../test_helper/assertions'

setup() {
  common_setup
  export ORIGINAL_PATH="$PATH"

  TEST_BARE="${TEST_TEMP}/remote.git"
  create_bare_remote "$TEST_BARE"
  export MOCK_GH_CLONE_SOURCE="$TEST_BARE"
  export MOCK_GH_REPO_EXISTS=false

  # Full setup
  bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default" >/dev/null 2>&1
}

teardown() {
  common_teardown
}

@test "create profile, push to it, pull from it" {
  # Create work profile
  run bash "${SCRIPTS_DIR}/profile-manager.sh" create work
  [ "$status" -eq 0 ]

  # Switch to work profile
  local sf="${CLAUDE_PLUGIN_DATA}/state.json"
  local tmp
  tmp=$(mktemp)
  jq '.active_profile = "work"' "$sf" > "$tmp" && mv "$tmp" "$sf"

  # Push config to work profile
  create_sample_project "$CLAUDE_PROJECT_DIR"
  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 0 ]

  # Wipe local
  rm -rf "${CLAUDE_PROJECT_DIR}/.claude" "${CLAUDE_PROJECT_DIR}/.auto-memory" "${CLAUDE_PROJECT_DIR}/.mcp.json"

  # Pull from work profile
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]
  [ -f "${CLAUDE_PROJECT_DIR}/.mcp.json" ]
}

@test "two profiles with different configs" {
  create_sample_project "$CLAUDE_PROJECT_DIR"
  echo '{"default_config": true}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Create work profile
  bash "${SCRIPTS_DIR}/profile-manager.sh" create work >/dev/null 2>&1
  local sf="${CLAUDE_PLUGIN_DATA}/state.json"
  local tmp
  tmp=$(mktemp)
  jq '.active_profile = "work"' "$sf" > "$tmp" && mv "$tmp" "$sf"

  echo '{"work_config": true}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Verify both profiles have different content
  local repo="${CLAUDE_PLUGIN_DATA}/repo"
  run cat "${repo}/profiles/default/mcp.json"
  [[ "$output" == *"default_config"* ]]
  run cat "${repo}/profiles/work/mcp.json"
  [[ "$output" == *"work_config"* ]]
}

@test "switch profile and pull restores that profile" {
  # Push to default
  create_sample_project "$CLAUDE_PROJECT_DIR"
  echo '{"profile":"default"}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Create and push to work
  bash "${SCRIPTS_DIR}/profile-manager.sh" create work >/dev/null 2>&1
  local sf="${CLAUDE_PLUGIN_DATA}/state.json"
  local tmp
  tmp=$(mktemp)
  jq '.active_profile = "work"' "$sf" > "$tmp" && mv "$tmp" "$sf"
  echo '{"profile":"work"}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Switch back to default and pull
  tmp=$(mktemp)
  jq '.active_profile = "default"' "$sf" > "$tmp" && mv "$tmp" "$sf"
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes --no-backup
  [ "$status" -eq 0 ]

  run cat "${CLAUDE_PROJECT_DIR}/.mcp.json"
  [[ "$output" == *'"profile":"default"'* ]] || [[ "$output" == *'"profile": "default"'* ]]
}

@test "delete profile does not affect other profiles" {
  bash "${SCRIPTS_DIR}/profile-manager.sh" create staging >/dev/null 2>&1
  bash "${SCRIPTS_DIR}/profile-manager.sh" delete staging >/dev/null 2>&1

  # Default should still work fine
  create_sample_project "$CLAUDE_PROJECT_DIR"
  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 0 ]
}

@test "create profile from existing preserves content" {
  # Push some content to default
  create_sample_project "$CLAUDE_PROJECT_DIR"
  echo '{"original": true}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Create clone from default
  run bash "${SCRIPTS_DIR}/profile-manager.sh" create clone --from default
  [ "$status" -eq 0 ]

  # Verify clone has default's files
  local repo="${CLAUDE_PLUGIN_DATA}/repo"
  [ -f "${repo}/profiles/clone/mcp.json" ]
  run cat "${repo}/profiles/clone/mcp.json"
  [[ "$output" == *"original"* ]]
}
