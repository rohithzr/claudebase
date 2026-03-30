#!/usr/bin/env bats
# Integration tests for sync-push.sh

load '../test_helper/common'
load '../test_helper/fixtures'
load '../test_helper/assertions'

setup() {
  common_setup
  export ORIGINAL_PATH="$PATH"

  # Create bare remote and initialize it
  TEST_BARE="${TEST_TEMP}/remote.git"
  create_bare_remote "$TEST_BARE"
  export MOCK_GH_CLONE_SOURCE="$TEST_BARE"
  initialize_remote_with_profile "$TEST_BARE" "default" "test-machine"

  # Clone into plugin data
  setup_local_repo_clone "$TEST_BARE" "${CLAUDE_PLUGIN_DATA}/repo"

  # Configure git in the clone
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  git config user.email "test@test.com"
  git config user.name "Test User"
  cd - >/dev/null

  # Create state file
  create_state_file "$CLAUDE_PLUGIN_DATA" "test-machine" "default"

  # Create sample project
  create_sample_project "$CLAUDE_PROJECT_DIR"
}

teardown() {
  common_teardown
}

@test "pushes project config files to repo" {
  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pushed"* ]]

  local repo="${CLAUDE_PLUGIN_DATA}/repo"
  assert_synced_to_repo "$repo" "default" "mcp.json"
  assert_synced_to_repo "$repo" "default" "settings.json"
}

@test "pushes all directory types" {
  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 0 ]

  local repo="${CLAUDE_PLUGIN_DATA}/repo"
  assert_synced_to_repo "$repo" "default" "agents/review.md"
  assert_synced_to_repo "$repo" "default" "commands/deploy.md"
  assert_synced_to_repo "$repo" "default" "skills/my-skill.md"
  assert_synced_to_repo "$repo" "default" "rules/style.md"
  assert_synced_to_repo "$repo" "default" "agent-memory/notes.md"
  assert_synced_to_repo "$repo" "default" "memory/context.md"
}

@test "skips files with detected secrets" {
  # Add a secret to mcp.json
  echo '{"key":"sk-abcdefghijklmnopqrstuvwxyz1234567890"}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"

  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [[ "$output" == *"secret"* ]] || [[ "$output" == *"Skipping"* ]]
}

@test "force flag overrides secret detection" {
  echo '{"key":"sk-abcdefghijklmnopqrstuvwxyz1234567890"}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"

  run bash "${SCRIPTS_DIR}/sync-push.sh" --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"Force-pushing"* ]] || [[ "$output" == *"Pushed"* ]]
}

@test "dry-run shows changes without committing" {
  run bash "${SCRIPTS_DIR}/sync-push.sh" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]] || [[ "$output" == *"Dry run"* ]]

  # Verify no new commits were made
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  local count
  count=$(git log --oneline | wc -l | tr -d ' ')
  [ "$count" -eq 1 ]  # Only the init commit
}

@test "exits when not set up" {
  rm -f "${CLAUDE_PLUGIN_DATA}/state.json"
  echo '{}' > "${CLAUDE_PLUGIN_DATA}/state.json"
  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not set up"* ]]
}

@test "auto mode exits 0 when not set up" {
  rm -f "${CLAUDE_PLUGIN_DATA}/state.json"
  echo '{}' > "${CLAUDE_PLUGIN_DATA}/state.json"
  run bash "${SCRIPTS_DIR}/sync-push.sh" --auto
  [ "$status" -eq 0 ]
}

@test "detects no changes and exits cleanly" {
  # Push once
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Push again — no changes
  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No changes"* ]]
}

@test "commits with correct message format" {
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  cd "${CLAUDE_PLUGIN_DATA}/repo"
  run git log -1 --pretty=format:"%s"
  [[ "$output" == *"Sync profile 'default'"* ]]
  [[ "$output" == *"test-machine"* ]]
}

@test "multi-machine conflict blocks push" {
  # Set metadata to show a different machine pushed last
  local meta="${CLAUDE_PLUGIN_DATA}/repo/.sync-meta.json"
  local tmp
  tmp=$(mktemp)
  jq '.profiles.default.last_push_machine = "other-machine" | .profiles.default.last_push = "2026-01-15T10:00:00Z"' "$meta" > "$tmp" && mv "$tmp" "$meta"
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  git add -A && git commit -m "update meta" --quiet
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"other-machine"* ]]
}

@test "multi-machine conflict skipped in auto mode" {
  local meta="${CLAUDE_PLUGIN_DATA}/repo/.sync-meta.json"
  local tmp
  tmp=$(mktemp)
  jq '.profiles.default.last_push_machine = "other-machine" | .profiles.default.last_push = "2026-01-15T10:00:00Z"' "$meta" > "$tmp" && mv "$tmp" "$meta"
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  git add -A && git commit -m "update meta" --quiet
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/sync-push.sh" --auto
  [ "$status" -eq 0 ]
  [[ "$output" == *"Skipping"* ]]
}

@test "force flag overrides multi-machine conflict" {
  local meta="${CLAUDE_PLUGIN_DATA}/repo/.sync-meta.json"
  local tmp
  tmp=$(mktemp)
  jq '.profiles.default.last_push_machine = "other-machine" | .profiles.default.last_push = "2026-01-15T10:00:00Z"' "$meta" > "$tmp" && mv "$tmp" "$meta"
  cd "${CLAUDE_PLUGIN_DATA}/repo"
  git add -A && git commit -m "update meta" --quiet
  cd - >/dev/null

  run bash "${SCRIPTS_DIR}/sync-push.sh" --force
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pushed"* ]]
}

@test "updates .sync-meta.json with push metadata" {
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  local meta="${CLAUDE_PLUGIN_DATA}/repo/.sync-meta.json"
  run jq -r '.profiles.default.last_push_machine' "$meta"
  [ "$output" = "test-machine" ]
  run jq -r '.profiles.default.last_push' "$meta"
  [ "$output" != "null" ]
}

@test "updates state with last_push timestamp" {
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  run jq -r '.last_push' "${CLAUDE_PLUGIN_DATA}/state.json"
  [ "$output" != "null" ]
  [ "$output" != "" ]
}

@test "include-global syncs global settings" {
  mkdir -p "${HOME}/.claude"
  echo '{"global": true}' > "${HOME}/.claude/settings.json"

  run bash "${SCRIPTS_DIR}/sync-push.sh" --include-global
  [ "$status" -eq 0 ]

  [ -f "${CLAUDE_PLUGIN_DATA}/repo/global/settings.json" ]
}
