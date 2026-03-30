#!/usr/bin/env bats
# Unit tests for common.sh secret scanning

load '../test_helper/common'

setup() {
  common_setup
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
}

teardown() {
  common_teardown
}

@test "scan_for_secrets passes clean file" {
  run scan_for_secrets "${FIXTURES_DIR}/secrets/clean_file.json"
  [ "$status" -eq 0 ]
}

@test "scan_for_secrets detects OpenAI API key (sk-)" {
  run scan_for_secrets "${FIXTURES_DIR}/secrets/file_with_api_key.json"
  [ "$status" -eq 1 ]
  [[ "$output" == *"secret"* ]]
}

@test "scan_for_secrets detects GitHub PAT (ghp_)" {
  run scan_for_secrets "${FIXTURES_DIR}/secrets/file_with_ghp_token.json"
  [ "$status" -eq 1 ]
}

@test "scan_for_secrets detects AWS access key (AKIA)" {
  run scan_for_secrets "${FIXTURES_DIR}/secrets/file_with_aws_key.json"
  [ "$status" -eq 1 ]
}

@test "scan_for_secrets detects PEM private key" {
  run scan_for_secrets "${FIXTURES_DIR}/secrets/file_with_pem.txt"
  [ "$status" -eq 1 ]
}

@test "scan_for_secrets detects Bearer token" {
  run scan_for_secrets "${FIXTURES_DIR}/secrets/file_with_bearer.json"
  [ "$status" -eq 1 ]
}

@test "scan_for_secrets returns 0 for nonexistent file" {
  run scan_for_secrets "/nonexistent/file.json"
  [ "$status" -eq 0 ]
}

@test "scan_for_secrets returns 0 for empty file" {
  local empty_file="${TEST_TEMP}/empty.json"
  touch "$empty_file"
  run scan_for_secrets "$empty_file"
  [ "$status" -eq 0 ]
}

@test "scan_for_secrets detects secrets in nested JSON values" {
  local nested="${TEST_TEMP}/nested.json"
  cat > "$nested" <<'EOF'
{
  "config": {
    "deep": {
      "key": "sk-abcdefghijklmnopqrstuvwxyz1234567890"
    }
  }
}
EOF
  run scan_for_secrets "$nested"
  [ "$status" -eq 1 ]
}

@test "scan_for_secrets does not false-positive on short strings" {
  local safe="${TEST_TEMP}/short.json"
  echo '{"key": "sk-short"}' > "$safe"
  run scan_for_secrets "$safe"
  [ "$status" -eq 0 ]
}
