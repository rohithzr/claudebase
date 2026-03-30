#!/usr/bin/env bash
# machine_sim.bash — Multi-machine simulation helpers for E2E tests
# Each "machine" gets its own PLUGIN_DATA, PROJECT_DIR, HOME, and machine_id
# All machines share a single bare repo as the "remote"

# Create an isolated machine environment
# Usage: create_machine "machine_name"
# After calling, use run_as_machine to execute scripts as that machine
create_machine() {
  local name="$1"
  local base="${TEST_TEMP}/machines/${name}"

  mkdir -p "${base}/plugin_data" "${base}/project/.claude" "${base}/home/.claude"

  # Create git config for this machine's HOME
  cat > "${base}/home/.gitconfig" <<EOF
[user]
    email = ${name}@test.com
    name = ${name}
[init]
    defaultBranch = main
EOF

  # Set up state with this machine's identity
  cat > "${base}/plugin_data/state.json" <<EOF
{
  "machine_id": "${name}",
  "setup_complete": "true",
  "repo_name": "claude-config",
  "repo_full": "testuser/claude-config",
  "active_profile": "default",
  "setup_date": "2026-01-01T00:00:00Z"
}
EOF

  # Create backups dir
  mkdir -p "${base}/plugin_data/backups"
}

# Clone the shared bare repo for a specific machine
# Must be called after create_machine and after the bare repo is initialized
setup_machine_repo() {
  local name="$1"
  local bare_repo="$2"
  local base="${TEST_TEMP}/machines/${name}"

  git clone "$bare_repo" "${base}/plugin_data/repo" --quiet 2>/dev/null

  # Configure git in the clone
  cd "${base}/plugin_data/repo"
  git config user.email "${name}@test.com"
  git config user.name "${name}"
  cd - >/dev/null
}

# Run a script as a specific machine
# Usage: run_as_machine "machine_name" script.sh [args...]
run_as_machine() {
  local name="$1"; shift
  local script="$1"; shift
  local base="${TEST_TEMP}/machines/${name}"

  CLAUDE_PLUGIN_DATA="${base}/plugin_data" \
  CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" \
  CLAUDE_PROJECT_DIR="${base}/project" \
  HOME="${base}/home" \
  GIT_CONFIG_GLOBAL="${base}/home/.gitconfig" \
  MOCK_GH_CALLS_LOG="${base}/gh_calls.log" \
  MOCK_GH_USER="testuser" \
  MOCK_GH_AUTHENTICATED="true" \
  MOCK_GH_REPO_EXISTS="true" \
  PATH="${MOCK_BIN}:${ORIGINAL_PATH}" \
  bash "${SCRIPTS_DIR}/${script}" "$@"
}

# Get a machine's project directory
get_machine_project() {
  local name="$1"
  echo "${TEST_TEMP}/machines/${name}/project"
}

# Get a machine's plugin data directory
get_machine_data() {
  local name="$1"
  echo "${TEST_TEMP}/machines/${name}/plugin_data"
}

# Get a machine's repo clone path
get_machine_repo() {
  local name="$1"
  echo "${TEST_TEMP}/machines/${name}/plugin_data/repo"
}
