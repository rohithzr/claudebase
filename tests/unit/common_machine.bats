#!/usr/bin/env bats
# Unit tests for common.sh machine ID

load '../test_helper/common'

setup() {
  common_setup
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
}

teardown() {
  common_teardown
}

@test "get_machine_id returns cached machine_id from state" {
  echo '{"machine_id":"my-laptop"}' > "$STATE_FILE"
  run get_machine_id
  [ "$output" = "my-laptop" ]
}

@test "get_machine_id generates from hostname when not cached" {
  echo '{}' > "$STATE_FILE"
  local expected
  expected=$(hostname -s 2>/dev/null || echo "unknown")
  run get_machine_id
  [ "$output" = "$expected" ]
  # Should also persist it to state
  run jq -r '.machine_id' "$STATE_FILE"
  [ "$output" = "$expected" ]
}

@test "get_machine_id returns value consistently on repeated calls" {
  echo '{"machine_id":"consistent"}' > "$STATE_FILE"
  local first second
  first=$(get_machine_id)
  second=$(get_machine_id)
  [ "$first" = "$second" ]
}
