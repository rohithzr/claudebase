#!/usr/bin/env bash
# assertions.bash — Custom assertion helpers for BATS tests

# Assert a file was synced to the repo profile directory
assert_synced_to_repo() {
  local repo_path="$1"
  local profile="$2"
  local relative_path="$3"
  local full_path="${repo_path}/profiles/${profile}/${relative_path}"
  if [[ ! -e "$full_path" ]]; then
    echo "Expected synced file not found: ${full_path}" >&2
    return 1
  fi
}

# Assert state file contains key with expected value
assert_state_value() {
  local state_file="$1"
  local key="$2"
  local expected="$3"
  local actual
  actual=$(jq -r ".${key}" "$state_file" 2>/dev/null)
  if [[ "$actual" != "$expected" ]]; then
    echo "State key '${key}': expected '${expected}', got '${actual}'" >&2
    return 1
  fi
}

# Assert gh mock was called with specific args
assert_gh_called_with() {
  local pattern="$1"
  if [[ ! -f "$MOCK_GH_CALLS_LOG" ]]; then
    echo "No gh calls logged" >&2
    return 1
  fi
  if ! grep -q "$pattern" "$MOCK_GH_CALLS_LOG"; then
    echo "Expected gh call matching '${pattern}' not found. Logged calls:" >&2
    cat "$MOCK_GH_CALLS_LOG" >&2
    return 1
  fi
}

# Assert gh mock was NOT called with specific args
assert_gh_not_called_with() {
  local pattern="$1"
  if [[ -f "$MOCK_GH_CALLS_LOG" ]] && grep -q "$pattern" "$MOCK_GH_CALLS_LOG"; then
    echo "Unexpected gh call matching '${pattern}' found. Logged calls:" >&2
    cat "$MOCK_GH_CALLS_LOG" >&2
    return 1
  fi
}

# Assert a backup directory exists with at least one backup
assert_backup_exists() {
  local backups_dir="$1"
  local count
  count=$(ls -d "${backups_dir}"/backup-* 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -eq 0 ]]; then
    echo "No backups found in ${backups_dir}" >&2
    return 1
  fi
}

# Assert backup count is exactly N
assert_backup_count() {
  local backups_dir="$1"
  local expected="$2"
  local count
  count=$(ls -d "${backups_dir}"/backup-* 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -ne "$expected" ]]; then
    echo "Expected ${expected} backup(s), found ${count}" >&2
    return 1
  fi
}

# Assert .sync-meta.json has a specific profile
assert_meta_has_profile() {
  local meta_file="$1"
  local profile="$2"
  local exists
  exists=$(jq -r ".profiles.\"${profile}\" // empty" "$meta_file" 2>/dev/null)
  if [[ -z "$exists" ]]; then
    echo "Profile '${profile}' not found in metadata" >&2
    return 1
  fi
}

# Assert .sync-meta.json does NOT have a specific profile
assert_meta_missing_profile() {
  local meta_file="$1"
  local profile="$2"
  local exists
  exists=$(jq -r ".profiles.\"${profile}\" // empty" "$meta_file" 2>/dev/null)
  if [[ -n "$exists" ]]; then
    echo "Profile '${profile}' unexpectedly found in metadata" >&2
    return 1
  fi
}
