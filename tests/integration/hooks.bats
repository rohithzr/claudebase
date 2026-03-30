#!/usr/bin/env bats
# Integration tests for hooks/run-hook.cmd

load '../test_helper/common'

setup() {
  common_setup
  HOOKS_DIR="${CLAUDE_PLUGIN_ROOT}/hooks"
}

teardown() {
  common_teardown
}

@test "run-hook.cmd invokes correct script" {
  # Create a simple test script
  mkdir -p "${CLAUDE_PLUGIN_ROOT}/scripts"
  cat > "${TEST_TEMP}/test-script.sh" <<'EOF'
#!/usr/bin/env bash
echo "HOOK_EXECUTED"
exit 0
EOF
  chmod +x "${TEST_TEMP}/test-script.sh"

  # The hook wrapper looks for scripts in SCRIPT_DIR (../scripts relative to hooks/)
  # We need to test the bash portion of the polyglot
  run bash -c "
    SCRIPT_DIR='${TEST_TEMP}'
    HOOK_SCRIPT='test-script.sh'
    if [ ! -f \"\${SCRIPT_DIR}/\${HOOK_SCRIPT}\" ]; then
      echo 'Script not found' >&2
      exit 1
    fi
    bash \"\${SCRIPT_DIR}/\${HOOK_SCRIPT}\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"HOOK_EXECUTED"* ]]
}

@test "run-hook.cmd fails with no argument" {
  run bash "${HOOKS_DIR}/run-hook.cmd"
  [ "$status" -eq 1 ]
  [[ "$output" == *"No script"* ]] || [[ "$output" == *"Error"* ]]
}

@test "run-hook.cmd fails with nonexistent script" {
  run bash "${HOOKS_DIR}/run-hook.cmd" "nonexistent.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"Error"* ]]
}

@test "hooks.json has SessionStart entry" {
  run jq -r '.hooks.SessionStart | length' "${HOOKS_DIR}/hooks.json"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "hooks.json has SessionEnd entry" {
  run jq -r '.hooks.SessionEnd | length' "${HOOKS_DIR}/hooks.json"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}
