#!/usr/bin/env bats
# Integration tests for profile-manager.sh

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
  cd - >/dev/null

  create_state_file "$CLAUDE_PLUGIN_DATA" "test-machine" "default"
}

teardown() {
  common_teardown
}

@test "list shows all profiles" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"default"* ]]
}

@test "list marks active profile" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Active profile"* ]]
  [[ "$output" == *"default"* ]]
}

@test "create makes new empty profile" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" create staging
  [ "$status" -eq 0 ]
  [[ "$output" == *"created"* ]]

  [ -d "${CLAUDE_PLUGIN_DATA}/repo/profiles/staging" ]
  assert_meta_has_profile "${CLAUDE_PLUGIN_DATA}/repo/.sync-meta.json" "staging"
}

@test "create from existing profile copies files" {
  # Add some files to default first
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  echo "# agent" > profiles/default/agents/test.md 2>/dev/null || {
    mkdir -p profiles/default/agents
    echo "# agent" > profiles/default/agents/test.md
  }
  git add -A && git commit -m "add file" --quiet
  git push --quiet 2>/dev/null
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/profile-manager.sh" create staging --from default
  [ "$status" -eq 0 ]

  [ -f "${CLAUDE_PLUGIN_DATA}/repo/profiles/staging/agents/test.md" ]
}

@test "create rejects invalid name characters" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" create "bad name!"
  [ "$status" -eq 1 ]
  [[ "$output" == *"alphanumeric"* ]]
}

@test "create rejects duplicate name" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" create default
  [ "$status" -eq 1 ]
  [[ "$output" == *"already exists"* ]]
}

@test "create from nonexistent source fails" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" create new-prof --from nonexistent
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "delete removes profile directory" {
  # Create a profile first
  bash "${SCRIPTS_DIR}/profile-manager.sh" create staging >/dev/null 2>&1

  run bash "${SCRIPTS_DIR}/profile-manager.sh" delete staging
  [ "$status" -eq 0 ]
  [ ! -d "${CLAUDE_PLUGIN_DATA}/repo/profiles/staging" ]
}

@test "delete refuses to delete active profile" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" delete default
  [ "$status" -eq 1 ]
  [[ "$output" == *"active profile"* ]] || [[ "$output" == *"Cannot delete"* ]]
}

@test "delete of nonexistent profile fails" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" delete ghost
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "delete updates .sync-meta.json" {
  bash "${SCRIPTS_DIR}/profile-manager.sh" create staging >/dev/null 2>&1

  bash "${SCRIPTS_DIR}/profile-manager.sh" delete staging >/dev/null 2>&1
  assert_meta_missing_profile "${CLAUDE_PLUGIN_DATA}/repo/.sync-meta.json" "staging"
}

@test "info shows profile details" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" info default
  [ "$status" -eq 0 ]
  [[ "$output" == *"Profile: default"* ]] || [[ "$output" == *"default"* ]]
  [[ "$output" == *"Created"* ]] || [[ "$output" == *"created"* ]]
}

@test "info for nonexistent profile fails" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" info ghost
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}

@test "diff between identical profiles shows no changes" {
  # Create a copy
  bash "${SCRIPTS_DIR}/profile-manager.sh" create staging --from default >/dev/null 2>&1

  run bash "${SCRIPTS_DIR}/profile-manager.sh" diff default staging
  [ "$status" -eq 0 ]
  [[ "$output" == *"identical"* ]]
}

@test "diff between different profiles shows differences" {
  bash "${SCRIPTS_DIR}/profile-manager.sh" create staging >/dev/null 2>&1

  # Add a file only to default
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  mkdir -p profiles/default/agents
  echo "# only in default" > profiles/default/agents/special.md
  git add -A && git commit -m "add special" --quiet
  git push --quiet 2>/dev/null
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/profile-manager.sh" diff default staging
  [ "$status" -eq 0 ]
  [[ "$output" == *"difference"* ]] || [[ "$output" == *"only"* ]]
}

@test "diff with missing profile fails" {
  run bash "${SCRIPTS_DIR}/profile-manager.sh" diff default ghost
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not exist"* ]]
}
