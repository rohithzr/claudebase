#!/usr/bin/env bash
# common.bash — Primary test helper loaded by every BATS test file

SCRIPTS_DIR="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)/scripts"
FIXTURES_DIR="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)/fixtures"

common_setup() {
  TEST_TEMP="$(mktemp -d)"
  export TEST_TEMP

  export CLAUDE_PLUGIN_DATA="${TEST_TEMP}/plugin_data"
  export CLAUDE_PLUGIN_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
  export CLAUDE_PROJECT_DIR="${TEST_TEMP}/project"
  export HOME="${TEST_TEMP}/home"

  mkdir -p "$CLAUDE_PLUGIN_DATA" "${TEST_TEMP}/project/.claude" "${HOME}/.claude"

  # Install gh mock
  MOCK_BIN="${TEST_TEMP}/mock_bin"
  mkdir -p "$MOCK_BIN"
  local helper_dir
  helper_dir="$(cd "${BATS_TEST_DIRNAME}/../test_helper" && pwd)"
  cp "${helper_dir}/mock_gh.bash" "${MOCK_BIN}/gh"
  chmod +x "${MOCK_BIN}/gh"
  export ORIGINAL_PATH="$PATH"
  export PATH="${MOCK_BIN}:${PATH}"
  export MOCK_BIN

  # Mock env vars
  export MOCK_GH_CALLS_LOG="${TEST_TEMP}/gh_calls.log"
  export MOCK_GH_USER="testuser"
  export MOCK_GH_AUTHENTICATED="true"
  export MOCK_GH_REPO_EXISTS="true"

  # Git config for tests
  export GIT_CONFIG_GLOBAL="${TEST_TEMP}/gitconfig"
  cat > "$GIT_CONFIG_GLOBAL" <<'EOF'
[user]
    email = test@test.com
    name = Test User
[init]
    defaultBranch = main
EOF
}

common_teardown() {
  if [[ -n "$TEST_TEMP" && -d "$TEST_TEMP" ]]; then
    rm -rf "$TEST_TEMP"
  fi
}

# Load bats-support and bats-assert
load "$(cd "${BATS_TEST_DIRNAME}/../test_helper/bats-support" && pwd)/load.bash"
load "$(cd "${BATS_TEST_DIRNAME}/../test_helper/bats-assert" && pwd)/load.bash"
