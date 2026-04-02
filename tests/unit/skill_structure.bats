#!/usr/bin/env bats
# Unit tests for skill directory structure and SKILL.md validation

SKILLS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../skills" && pwd)"

@test "each skill directory contains a SKILL.md" {
  for dir in "$SKILLS_DIR"/*/; do
    [ -f "${dir}SKILL.md" ]
  done
}

@test "SKILL.md name field matches directory name" {
  for dir in "$SKILLS_DIR"/*/; do
    local dirname
    dirname="$(basename "$dir")"
    local name
    name="$(grep '^name:' "${dir}SKILL.md" | head -1 | sed 's/^name:[[:space:]]*//')"
    [ "$name" = "$dirname" ]
  done
}

@test "SKILL.md description starts with 'Use when'" {
  for dir in "$SKILLS_DIR"/*/; do
    local desc
    desc="$(grep '^description:' "${dir}SKILL.md" | head -1 | sed 's/^description:[[:space:]]*//')"
    [[ "$desc" == "Use when"* ]]
  done
}

@test "SKILL.md has user-invocable set to true" {
  for dir in "$SKILLS_DIR"/*/; do
    grep -q '^user-invocable: true' "${dir}SKILL.md"
  done
}

@test "all skill directories use sync- prefix" {
  for dir in "$SKILLS_DIR"/*/; do
    local dirname
    dirname="$(basename "$dir")"
    [[ "$dirname" == sync-* ]]
  done
}

@test "exactly 6 skills exist" {
  local count
  count="$(ls -d "$SKILLS_DIR"/*/ | wc -l | tr -d ' ')"
  [ "$count" -eq 6 ]
}
