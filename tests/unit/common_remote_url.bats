#!/usr/bin/env bats
# Unit tests for get_remote_url() in common.sh
#
# get_remote_url reads gh's configured git protocol and returns the right
# remote URL format. This locks in the ssh/https branching so a future
# refactor can't silently regress back to hard-coded HTTPS.

load '../test_helper/common'

setup() {
  common_setup
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
}

teardown() {
  common_teardown
}

@test "get_remote_url returns ssh URL when gh git_protocol is ssh" {
  export MOCK_GH_PROTOCOL=ssh
  run get_remote_url "testuser/claude-config"
  [ "$status" -eq 0 ]
  [ "$output" = "git@github.com:testuser/claude-config.git" ]
}

@test "get_remote_url returns https URL when gh git_protocol is https" {
  export MOCK_GH_PROTOCOL=https
  run get_remote_url "testuser/claude-config"
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/testuser/claude-config.git" ]
}

@test "get_remote_url falls back to https when gh git_protocol is unset" {
  unset MOCK_GH_PROTOCOL
  run get_remote_url "testuser/claude-config"
  [ "$status" -eq 0 ]
  [ "$output" = "https://github.com/testuser/claude-config.git" ]
}

@test "get_remote_url handles owner names with dashes" {
  export MOCK_GH_PROTOCOL=ssh
  run get_remote_url "my-org/my-repo"
  [ "$output" = "git@github.com:my-org/my-repo.git" ]
}
