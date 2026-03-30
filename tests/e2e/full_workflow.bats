#!/usr/bin/env bats
# E2E tests: complete setup → push → pull → status workflows

load '../test_helper/common'
load '../test_helper/fixtures'
load '../test_helper/assertions'

setup() {
  common_setup
  export ORIGINAL_PATH="$PATH"

  TEST_BARE="${TEST_TEMP}/remote.git"
  create_bare_remote "$TEST_BARE"
  export MOCK_GH_CLONE_SOURCE="$TEST_BARE"
  export MOCK_GH_REPO_EXISTS=false
}

teardown() {
  common_teardown
}

@test "complete setup-push-pull-status cycle" {
  # Step 1: Setup
  run bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default"
  [ "$status" -eq 0 ]

  # Step 2: Create project config
  create_sample_project "$CLAUDE_PROJECT_DIR"

  # Step 3: Push
  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pushed"* ]]

  # Step 4: Wipe local config
  rm -rf "${CLAUDE_PROJECT_DIR}/.mcp.json" "${CLAUDE_PROJECT_DIR}/.claude" "${CLAUDE_PROJECT_DIR}/.auto-memory"

  # Step 5: Pull
  run bash "${SCRIPTS_DIR}/sync-pull.sh" --yes
  [ "$status" -eq 0 ]

  # Step 6: Verify files restored
  [ -f "${CLAUDE_PROJECT_DIR}/.mcp.json" ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/settings.json" ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/agents/review.md" ]

  # Step 7: Status should show in-sync
  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"in sync"* ]]
}

@test "push then pull preserves file contents exactly" {
  bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default" >/dev/null 2>&1

  # Create specific content
  mkdir -p "${CLAUDE_PROJECT_DIR}/.claude"
  echo '{"model":"opus","context":1000000}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"
  echo '{"permissions":{"allow":["Read","Write"]}}' > "${CLAUDE_PROJECT_DIR}/.claude/settings.json"

  # Push
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Save original content
  local orig_mcp orig_settings
  orig_mcp=$(cat "${CLAUDE_PROJECT_DIR}/.mcp.json")
  orig_settings=$(cat "${CLAUDE_PROJECT_DIR}/.claude/settings.json")

  # Wipe and pull
  rm -f "${CLAUDE_PROJECT_DIR}/.mcp.json" "${CLAUDE_PROJECT_DIR}/.claude/settings.json"
  bash "${SCRIPTS_DIR}/sync-pull.sh" --yes >/dev/null 2>&1

  # Verify content is identical
  [ "$(cat "${CLAUDE_PROJECT_DIR}/.mcp.json")" = "$orig_mcp" ]
  [ "$(cat "${CLAUDE_PROJECT_DIR}/.claude/settings.json")" = "$orig_settings" ]
}

@test "push then pull preserves directory structures" {
  bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default" >/dev/null 2>&1

  create_sample_project "$CLAUDE_PROJECT_DIR"

  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Wipe everything
  rm -rf "${CLAUDE_PROJECT_DIR}/.claude" "${CLAUDE_PROJECT_DIR}/.auto-memory" "${CLAUDE_PROJECT_DIR}/.mcp.json"

  bash "${SCRIPTS_DIR}/sync-pull.sh" --yes >/dev/null 2>&1

  # Verify directory structure
  [ -d "${CLAUDE_PROJECT_DIR}/.claude/agents" ]
  [ -d "${CLAUDE_PROJECT_DIR}/.claude/commands" ]
  [ -d "${CLAUDE_PROJECT_DIR}/.claude/skills" ]
  [ -d "${CLAUDE_PROJECT_DIR}/.claude/rules" ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/agents/review.md" ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/commands/deploy.md" ]
}

@test "repeated push-pull cycles are stable" {
  bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default" >/dev/null 2>&1
  create_sample_project "$CLAUDE_PROJECT_DIR"

  for i in 1 2 3; do
    bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1
    rm -rf "${CLAUDE_PROJECT_DIR}/.claude" "${CLAUDE_PROJECT_DIR}/.auto-memory" "${CLAUDE_PROJECT_DIR}/.mcp.json"
    bash "${SCRIPTS_DIR}/sync-pull.sh" --yes --no-backup >/dev/null 2>&1
  done

  # After 3 cycles, files should still be correct
  [ -f "${CLAUDE_PROJECT_DIR}/.mcp.json" ]
  [ -f "${CLAUDE_PROJECT_DIR}/.claude/settings.json" ]
  run cat "${CLAUDE_PROJECT_DIR}/.mcp.json"
  [[ "$output" == *"mcpServers"* ]]
}

@test "status after push shows in-sync" {
  bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default" >/dev/null 2>&1
  create_sample_project "$CLAUDE_PROJECT_DIR"
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"in sync"* ]]
}

@test "status after local modification shows changes" {
  bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default" >/dev/null 2>&1
  create_sample_project "$CLAUDE_PROJECT_DIR"
  bash "${SCRIPTS_DIR}/sync-push.sh" >/dev/null 2>&1

  # Modify a file locally
  echo '{"modified": true}' > "${CLAUDE_PROJECT_DIR}/.mcp.json"

  run bash "${SCRIPTS_DIR}/diff-config.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"modified"* ]]
}

@test "dry-run followed by real push" {
  bash "${SCRIPTS_DIR}/ensure-repo.sh" "claude-config" "default" >/dev/null 2>&1
  create_sample_project "$CLAUDE_PROJECT_DIR"

  # Dry run
  run bash "${SCRIPTS_DIR}/sync-push.sh" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]] || [[ "$output" == *"Dry run"* ]]

  # Real push should still work (dry-run had no side effects)
  run bash "${SCRIPTS_DIR}/sync-push.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Pushed"* ]]
}
