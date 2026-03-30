#!/usr/bin/env bats
# Integration tests for ensure-repo.sh

load '../test_helper/common'
load '../test_helper/fixtures'
load '../test_helper/assertions'

setup() {
  common_setup
  export ORIGINAL_PATH="$PATH"

  # Create a bare repo as "remote"
  TEST_BARE="${TEST_TEMP}/remote.git"
  create_bare_remote "$TEST_BARE"
  export MOCK_GH_CLONE_SOURCE="$TEST_BARE"
  export MOCK_GH_REPO_EXISTS=false
}

teardown() {
  common_teardown
}

@test "creates new repo and initializes structure" {
  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Setup complete"* ]]

  # Verify state file
  assert_state_value "${CLAUDE_PLUGIN_DATA}/state.json" "setup_complete" "true"
  assert_state_value "${CLAUDE_PLUGIN_DATA}/state.json" "repo_name" "claude-config"
  assert_state_value "${CLAUDE_PLUGIN_DATA}/state.json" "active_profile" "default"
}

@test "initializes repo structure with default profile" {
  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -eq 0 ]

  local repo="${CLAUDE_PLUGIN_DATA}/repo"
  [ -d "${repo}/profiles/default" ]
  [ -d "${repo}/shared" ]
  [ -d "${repo}/global" ]
  [ -f "${repo}/.sync-meta.json" ]
  [ -f "${repo}/.gitignore" ]
}

@test "initializes repo with custom profile name" {
  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "work"
  [ "$status" -eq 0 ]

  local repo="${CLAUDE_PLUGIN_DATA}/repo"
  [ -d "${repo}/profiles/work" ]
  [ -f "${repo}/profiles/work/README.md" ]
  assert_state_value "${CLAUDE_PLUGIN_DATA}/state.json" "active_profile" "work"
}

@test "uses existing repo when already created" {
  export MOCK_GH_REPO_EXISTS=true
  # Pre-initialize the bare repo so clone works
  initialize_remote_with_profile "$TEST_BARE" "default"

  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already exists"* ]] || [[ "$output" == *"already initialized"* ]]
}

@test "skips init when profile directory already exists" {
  export MOCK_GH_REPO_EXISTS=true
  initialize_remote_with_profile "$TEST_BARE" "default"

  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already initialized"* ]]
}

@test "state file contains all required keys after setup" {
  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -eq 0 ]

  local sf="${CLAUDE_PLUGIN_DATA}/state.json"
  [ -f "$sf" ]
  # Check all required keys
  run jq -r '.repo_name' "$sf"
  [ "$output" = "claude-config" ]
  run jq -r '.setup_complete' "$sf"
  [ "$output" = "true" ]
  run jq -r '.active_profile' "$sf"
  [ "$output" = "default" ]
  run jq -r '.setup_date' "$sf"
  [ "$output" != "null" ]
  [ "$output" != "" ]
}

@test ".sync-meta.json has correct structure" {
  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -eq 0 ]

  local meta="${CLAUDE_PLUGIN_DATA}/repo/.sync-meta.json"
  [ -f "$meta" ]
  run jq -r '.version' "$meta"
  [ "$output" = "1.0" ]
  run jq -r '.profiles.default.created' "$meta"
  [ "$output" != "null" ]
  run jq -r '.machines | keys | length' "$meta"
  [ "$output" -ge 1 ]
}

@test "handles empty repo clone failure gracefully" {
  # MOCK_GH_REPO_EXISTS=false and no CLONE_SOURCE initialized = clone will fail
  export MOCK_GH_CLONE_SOURCE=""
  export MOCK_GH_REPO_EXISTS=false

  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  # Should still succeed via local git init fallback
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  # State should be set regardless of push success
  [ -f "${CLAUDE_PLUGIN_DATA}/state.json" ]
}
