#!/usr/bin/env bats
# Unit tests for common.sh GitHub helpers

load '../test_helper/common'

setup() {
  common_setup
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
}

teardown() {
  common_teardown
}

@test "check_gh succeeds when gh installed and authenticated" {
  export MOCK_GH_AUTHENTICATED=true
  run check_gh
  [ "$status" -eq 0 ]
}

@test "check_gh fails when gh not installed" {
  # Remove mock gh and restrict PATH to only have system essentials (no real gh)
  rm -f "${MOCK_BIN}/gh"
  PATH="${MOCK_BIN}:/usr/bin:/bin" run check_gh
  [ "$status" -eq 1 ]
  [[ "$output" == *"not installed"* ]]
}

@test "check_gh fails when gh not authenticated" {
  export MOCK_GH_AUTHENTICATED=false
  run check_gh
  [ "$status" -eq 1 ]
  [[ "$output" == *"not authenticated"* ]]
}

@test "check_jq succeeds when jq installed" {
  run check_jq
  [ "$status" -eq 0 ]
}

@test "check_jq fails when jq not installed" {
  # Hide jq temporarily
  local real_path="$PATH"
  export PATH="$MOCK_BIN"
  run check_jq
  [ "$status" -eq 1 ]
  [[ "$output" == *"not installed"* ]]
  export PATH="$real_path"
}

@test "get_gh_user returns login from mock" {
  run get_gh_user
  [ "$status" -eq 0 ]
  [ "$output" = "testuser" ]
}

@test "get_repo_name returns configured name from state" {
  echo '{"repo_name":"my-config"}' > "$STATE_FILE"
  run get_repo_name
  [ "$output" = "my-config" ]
}

@test "get_repo_name returns default when unconfigured" {
  echo '{}' > "$STATE_FILE"
  run get_repo_name
  [ "$output" = "claude-config" ]
}

@test "get_profile returns active_profile from state" {
  echo '{"active_profile":"work"}' > "$STATE_FILE"
  run get_profile ""
  [ "$output" = "work" ]
}

@test "get_profile returns default when unconfigured" {
  echo '{}' > "$STATE_FILE"
  run get_profile ""
  [ "$output" = "default" ]
}

@test "get_profile uses argument when provided" {
  echo '{"active_profile":"work"}' > "$STATE_FILE"
  run get_profile "custom"
  [ "$output" = "custom" ]
}
