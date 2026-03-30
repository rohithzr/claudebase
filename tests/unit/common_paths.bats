#!/usr/bin/env bats
# Unit tests for common.sh path resolution

load '../test_helper/common'

setup() {
  common_setup
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
}

teardown() {
  common_teardown
}

@test "PLUGIN_ROOT respects CLAUDE_PLUGIN_ROOT override" {
  [ "$PLUGIN_ROOT" = "$CLAUDE_PLUGIN_ROOT" ]
}

@test "PLUGIN_DATA respects CLAUDE_PLUGIN_DATA override" {
  export CLAUDE_PLUGIN_DATA="${TEST_TEMP}/custom_data"
  mkdir -p "$CLAUDE_PLUGIN_DATA"
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
  [ "$PLUGIN_DATA" = "${TEST_TEMP}/custom_data" ]
}

@test "PLUGIN_DATA defaults correctly" {
  local expected="${HOME}/.claude/plugins/data/claudebase"
  unset CLAUDE_PLUGIN_DATA
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
  [ "$PLUGIN_DATA" = "$expected" ]
}

@test "data directories are created on source" {
  [ -d "$PLUGIN_DATA" ]
  [ -d "$BACKUPS_DIR" ]
}

@test "get_local_repo_path returns PLUGIN_DATA/repo" {
  run get_local_repo_path
  [ "$output" = "${PLUGIN_DATA}/repo" ]
}

@test "STATE_FILE is inside PLUGIN_DATA" {
  [[ "$STATE_FILE" == "${PLUGIN_DATA}/state.json" ]]
}
