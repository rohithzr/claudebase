#!/usr/bin/env bats
# Unit tests for common.sh state management: get_state, set_state

load '../test_helper/common'

setup() {
  common_setup
  # Source common.sh functions (unset strict mode for test compat)
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
}

teardown() {
  common_teardown
}

@test "get_state returns default when state file missing" {
  rm -f "$STATE_FILE"
  run get_state "foo" "mydefault"
  [ "$status" -eq 0 ]
  [ "$output" = "mydefault" ]
}

@test "get_state returns empty default when state file missing and no default" {
  rm -f "$STATE_FILE"
  run get_state "foo"
  [ "$status" -eq 0 ]
  [ "$output" = "" ]
}

@test "get_state returns default when key missing from state" {
  echo '{"other":"value"}' > "$STATE_FILE"
  run get_state "missing_key" "fallback"
  [ "$status" -eq 0 ]
  [ "$output" = "fallback" ]
}

@test "get_state returns value when key exists" {
  echo '{"foo":"bar"}' > "$STATE_FILE"
  run get_state "foo" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "bar" ]
}

@test "get_state tolerates corrupt JSON gracefully" {
  echo '{bad json' > "$STATE_FILE"
  run get_state "foo" "safe_default"
  [ "$status" -eq 0 ]
  [ "$output" = "safe_default" ]
}

@test "set_state creates state file when missing" {
  rm -f "$STATE_FILE"
  set_state "newkey" "newval"
  [ -f "$STATE_FILE" ]
  run jq -r '.newkey' "$STATE_FILE"
  [ "$output" = "newval" ]
}

@test "set_state updates existing key" {
  echo '{"foo":"old"}' > "$STATE_FILE"
  set_state "foo" "new"
  run jq -r '.foo' "$STATE_FILE"
  [ "$output" = "new" ]
}

@test "set_state adds new key to existing file" {
  echo '{"a":"1"}' > "$STATE_FILE"
  set_state "b" "2"
  run jq -r '.a' "$STATE_FILE"
  [ "$output" = "1" ]
  run jq -r '.b' "$STATE_FILE"
  [ "$output" = "2" ]
}

@test "set_state preserves other keys when updating" {
  echo '{"keep":"this","change":"old"}' > "$STATE_FILE"
  set_state "change" "new"
  run jq -r '.keep' "$STATE_FILE"
  [ "$output" = "this" ]
  run jq -r '.change' "$STATE_FILE"
  [ "$output" = "new" ]
}

@test "get_state handles empty state file" {
  echo "" > "$STATE_FILE"
  run get_state "foo" "default"
  [ "$status" -eq 0 ]
  [ "$output" = "default" ]
}
