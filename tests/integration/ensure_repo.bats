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

@test "initializes empty remote repo via local git init path" {
  # Remote exists but is empty — gh repo view --json isEmpty returns "true".
  # ensure-repo.sh should skip `gh repo clone` and fall into the local
  # `git init + git remote add origin` branch, then push to the bare remote.
  export MOCK_GH_REPO_EXISTS=true
  export MOCK_GH_REPO_EMPTY=true

  # Redirect the github URL that ensure-repo.sh will set as origin to the
  # local bare remote so the push actually lands somewhere.
  git config --file "$GIT_CONFIG_GLOBAL" \
    "url.${TEST_BARE}.insteadOf" \
    "https://github.com/${MOCK_GH_USER}/claude-config.git"

  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Remote repo is empty"* ]]
  [[ "$output" == *"Setup complete"* ]]

  # Verify setup_complete was set — which means the push succeeded, since
  # the new code defers that state write until after the push.
  assert_state_value "${CLAUDE_PLUGIN_DATA}/state.json" "setup_complete" "true"

  # Verify the bare remote actually received the initial commit.
  run git --git-dir="$TEST_BARE" log --oneline main
  [ "$status" -eq 0 ]
  [[ "$output" == *"Initialize claudebase repo"* ]]
}

@test "exits nonzero with a helpful hint when clone fails" {
  # Simulate a real clone failure (SSH hostkey, network, auth). The script
  # must NOT silently fall back to local init, must exit nonzero, must
  # surface the actionable hint, and must NOT mark setup_complete=true.
  export MOCK_GH_REPO_EXISTS=true
  export MOCK_GH_REPO_EMPTY=false
  export MOCK_GH_CLONE_FAILS=true

  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Failed to clone"* ]]
  [[ "$output" == *"ssh -T git@github.com"* ]]

  # setup_complete must remain unset — the whole point of the fix.
  if [[ -f "${CLAUDE_PLUGIN_DATA}/state.json" ]]; then
    run jq -r '.setup_complete // "unset"' "${CLAUDE_PLUGIN_DATA}/state.json"
    [ "$output" != "true" ]
  fi
}
