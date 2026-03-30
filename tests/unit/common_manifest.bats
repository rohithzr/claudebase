#!/usr/bin/env bats
# Unit tests for common.sh manifest helpers

load '../test_helper/common'

setup() {
  common_setup
  source "${SCRIPTS_DIR}/common.sh" 2>/dev/null || true
  # Remove any leftover local manifest from previous tests
  rm -f "$MANIFEST_LOCAL"
}

teardown() {
  # Clean up local manifest override
  rm -f "$MANIFEST_LOCAL"
  common_teardown
}

@test "get_manifest_value reads from base manifest" {
  run get_manifest_value '.version'
  [ "$status" -eq 0 ]
  [ "$output" = "1.0" ]
}

@test "get_manifest_value reads secret_patterns array" {
  run get_manifest_value '.secret_patterns | length'
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "get_manifest_value merges local override" {
  # Create a local override that adds a field
  cat > "$MANIFEST_LOCAL" <<'EOF'
{
  "custom_field": "custom_value"
}
EOF
  run get_manifest_value '.custom_field'
  [ "$output" = "custom_value" ]
}

@test "get_manifest_value local overrides base for objects" {
  cat > "$MANIFEST_LOCAL" <<'EOF'
{
  "version": "2.0"
}
EOF
  run get_manifest_value '.version'
  [ "$output" = "2.0" ]
}

@test "get_manifest_value handles missing manifest gracefully" {
  # Point to non-existent manifest
  MANIFEST="/nonexistent/manifest.json"
  MANIFEST_LOCAL="/nonexistent/manifest.local.json"
  run get_manifest_value '.version'
  [ "$status" -eq 0 ]
}
