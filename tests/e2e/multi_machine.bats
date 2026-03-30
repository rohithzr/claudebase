#!/usr/bin/env bats
# E2E tests: multi-machine simulation (1-2-3 machines)

load '../test_helper/common'
load '../test_helper/fixtures'
load '../test_helper/assertions'
load '../test_helper/machine_sim'

setup() {
  common_setup
  export ORIGINAL_PATH="$PATH"

  # Shared bare remote
  TEST_BARE="${TEST_TEMP}/remote.git"
  create_bare_remote "$TEST_BARE"
  export MOCK_GH_CLONE_SOURCE="$TEST_BARE"
  initialize_remote_with_profile "$TEST_BARE" "default" "laptop"

  # Create machines
  create_machine "laptop"
  create_machine "desktop"
  setup_machine_repo "laptop" "$TEST_BARE"
  setup_machine_repo "desktop" "$TEST_BARE"
}

teardown() {
  common_teardown
}

@test "two machines push and pull same profile" {
  # Laptop creates config and pushes
  local laptop_project
  laptop_project=$(get_machine_project "laptop")
  create_sample_project "$laptop_project"
  run run_as_machine "laptop" sync-push.sh
  [ "$status" -eq 0 ]

  # Desktop pulls
  run run_as_machine "desktop" sync-pull.sh --yes
  [ "$status" -eq 0 ]

  local desktop_project
  desktop_project=$(get_machine_project "desktop")
  [ -f "${desktop_project}/.mcp.json" ]
  [ -f "${desktop_project}/.claude/settings.json" ]
}

@test "push from machine B after A warns about conflict" {
  # Laptop pushes
  local laptop_project
  laptop_project=$(get_machine_project "laptop")
  create_sample_project "$laptop_project"
  run_as_machine "laptop" sync-push.sh >/dev/null 2>&1

  # Desktop tries to push without pulling first
  local desktop_project
  desktop_project=$(get_machine_project "desktop")
  create_sample_project "$desktop_project"

  # Pull latest so desktop has the repo content, then modify
  run_as_machine "desktop" sync-pull.sh --yes --no-backup >/dev/null 2>&1
  echo '{"desktop_change": true}' > "${desktop_project}/.mcp.json"

  run run_as_machine "desktop" sync-push.sh
  [ "$status" -eq 1 ]
  [[ "$output" == *"laptop"* ]] || [[ "$output" == *"another"* ]] || [[ "$output" == *"Pull first"* ]]
}

@test "push from machine B with --force succeeds" {
  local laptop_project
  laptop_project=$(get_machine_project "laptop")
  create_sample_project "$laptop_project"
  run_as_machine "laptop" sync-push.sh >/dev/null 2>&1

  local desktop_project
  desktop_project=$(get_machine_project "desktop")
  create_sample_project "$desktop_project"
  # Update desktop repo
  run_as_machine "desktop" sync-pull.sh --yes --no-backup >/dev/null 2>&1
  echo '{"desktop_change": true}' > "${desktop_project}/.mcp.json"

  run run_as_machine "desktop" sync-push.sh --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pushed"* ]]
}

@test "pull from machine B updates metadata" {
  local laptop_project
  laptop_project=$(get_machine_project "laptop")
  create_sample_project "$laptop_project"
  run_as_machine "laptop" sync-push.sh >/dev/null 2>&1

  run run_as_machine "desktop" sync-pull.sh --yes
  [ "$status" -eq 0 ]

  local desktop_repo
  desktop_repo=$(get_machine_repo "desktop")
  run jq -r '.machines.desktop.last_seen' "${desktop_repo}/.sync-meta.json"
  [ "$output" != "null" ]
}

@test "three machines round-robin sync" {
  create_machine "ci"
  setup_machine_repo "ci" "$TEST_BARE"

  # Laptop pushes initial config
  local laptop_project
  laptop_project=$(get_machine_project "laptop")
  create_sample_project "$laptop_project"
  run_as_machine "laptop" sync-push.sh >/dev/null 2>&1

  # Desktop pulls, modifies, pushes
  run_as_machine "desktop" sync-pull.sh --yes --no-backup >/dev/null 2>&1
  local desktop_project
  desktop_project=$(get_machine_project "desktop")
  echo '{"desktop_modified": true}' > "${desktop_project}/.mcp.json"
  run_as_machine "desktop" sync-push.sh --force >/dev/null 2>&1

  # CI pulls — should get desktop's version
  run run_as_machine "ci" sync-pull.sh --yes
  [ "$status" -eq 0 ]

  local ci_project
  ci_project=$(get_machine_project "ci")
  run cat "${ci_project}/.mcp.json"
  [[ "$output" == *"desktop_modified"* ]]
}

@test "auto-push from second machine skipped on conflict" {
  local laptop_project
  laptop_project=$(get_machine_project "laptop")
  create_sample_project "$laptop_project"
  run_as_machine "laptop" sync-push.sh >/dev/null 2>&1

  local desktop_project
  desktop_project=$(get_machine_project "desktop")
  create_sample_project "$desktop_project"
  run_as_machine "desktop" sync-pull.sh --yes --no-backup >/dev/null 2>&1
  echo '{"change":true}' > "${desktop_project}/.mcp.json"

  run run_as_machine "desktop" sync-push.sh --auto
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping"* ]]
}

@test "machine IDs tracked in .sync-meta.json" {
  local laptop_project
  laptop_project=$(get_machine_project "laptop")
  create_sample_project "$laptop_project"
  run_as_machine "laptop" sync-push.sh >/dev/null 2>&1

  run_as_machine "desktop" sync-pull.sh --yes --no-backup >/dev/null 2>&1

  local desktop_repo
  desktop_repo=$(get_machine_repo "desktop")
  # Pull updates trigger metadata commit
  run jq -r '.machines | keys[]' "${desktop_repo}/.sync-meta.json"
  [[ "$output" == *"laptop"* ]]
  [[ "$output" == *"desktop"* ]]
}

@test "each machine sees correct last_push_machine" {
  local laptop_project
  laptop_project=$(get_machine_project "laptop")
  create_sample_project "$laptop_project"
  run_as_machine "laptop" sync-push.sh >/dev/null 2>&1

  local laptop_repo
  laptop_repo=$(get_machine_repo "laptop")
  run jq -r '.profiles.default.last_push_machine' "${laptop_repo}/.sync-meta.json"
  [ "$output" = "laptop" ]
}
