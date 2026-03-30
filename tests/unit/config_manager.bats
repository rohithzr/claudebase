#!/usr/bin/env bats
# Unit tests for config-manager.sh

load '../test_helper/common'

setup() {
  common_setup
  export CLAUDE_PLUGIN_DATA
  export CLAUDE_PLUGIN_ROOT
  export HOME
  # Create a valid state file
  cat > "${CLAUDE_PLUGIN_DATA}/state.json" <<'EOF'
{
  "setup_complete": "true",
  "repo_name": "claude-config",
  "repo_full": "testuser/claude-config",
  "active_profile": "default",
  "machine_id": "test-machine",
  "include_global": "false",
  "auto_push": "false"
}
EOF
}

teardown() {
  common_teardown
}

@test "show displays config keys" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" show
  [ "$status" -eq 0 ]
  [[ "$output" == *"active_profile"* ]]
  [[ "$output" == *"machine_id"* ]]
  [[ "$output" == *"include_global"* ]]
}

@test "show fails when not set up" {
  rm -f "${CLAUDE_PLUGIN_DATA}/state.json"
  run bash "${SCRIPTS_DIR}/config-manager.sh" show
  [ "$status" -eq 1 ]
  [[ "$output" == *"not set up"* ]]
}

@test "set updates a valid boolean key" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" set include_global true
  [ "$status" -eq 0 ]
  run jq -r '.include_global' "${CLAUDE_PLUGIN_DATA}/state.json"
  [ "$output" = "true" ]
}

@test "set rejects unknown key" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" set unknown_key value
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unknown"* ]]
}

@test "set validates boolean keys reject non-boolean" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" set auto_push maybe
  [ "$status" -eq 1 ]
  [[ "$output" == *"true"* ]] || [[ "$output" == *"false"* ]]
}

@test "set accepts machine_id with any string" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" set machine_id my-custom-laptop
  [ "$status" -eq 0 ]
  run jq -r '.machine_id' "${CLAUDE_PLUGIN_DATA}/state.json"
  [ "$output" = "my-custom-laptop" ]
}

@test "get returns existing value" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" get active_profile
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]
}

@test "get returns unset for missing key" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" get nonexistent
  [ "$status" -eq 0 ]
  [ "$output" = "unset" ]
}

@test "reset removes a resettable key" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" reset include_global
  [ "$status" -eq 0 ]
  run jq -r '.include_global // "gone"' "${CLAUDE_PLUGIN_DATA}/state.json"
  [ "$output" = "gone" ]
}

@test "reset rejects non-resettable keys" {
  run bash "${SCRIPTS_DIR}/config-manager.sh" reset machine_id
  [ "$status" -eq 1 ]
  [[ "$output" == *"Cannot reset"* ]]
}

@test "set and get are round-trip consistent" {
  bash "${SCRIPTS_DIR}/config-manager.sh" set machine_id round-trip-test
  run bash "${SCRIPTS_DIR}/config-manager.sh" get machine_id
  [ "$output" = "round-trip-test" ]
}
