#!/usr/bin/env bash
# ensure-repo.sh — Create or verify the GitHub config repo exists
set -euo pipefail
source "$(dirname "$0")/common.sh"

REPO_NAME="${1:-$(get_repo_name)}"
PROFILE="${2:-default}"

info "Checking dependencies..."
if ! check_jq; then exit 1; fi
if ! check_gh; then
  exit 1
fi

USER=$(get_gh_user)
REPO_FULL="${USER}/${REPO_NAME}"

info "Checking if repo ${REPO_FULL} exists..."
if gh repo view "$REPO_FULL" &>/dev/null; then
  ok "Repo ${REPO_FULL} already exists."
else
  info "Creating private repo ${REPO_FULL}..."
  gh repo create "$REPO_NAME" --private --description "Claude Code configuration sync" --clone=false
  ok "Created repo ${REPO_FULL}"
fi

# Save state
set_state "repo_name" "$REPO_NAME"
set_state "repo_full" "$REPO_FULL"
set_state "active_profile" "$PROFILE"
set_state "setup_complete" "true"
set_state "setup_date" "$(now_iso)"

# Clone/update local copy
info "Syncing local repo copy..."
REPO_PATH=$(get_local_repo_path)

if [[ -d "${REPO_PATH}/.git" ]]; then
  cd "$REPO_PATH"
  git remote set-url origin "https://github.com/${REPO_FULL}.git" 2>/dev/null || true
  git pull --rebase --quiet 2>/dev/null || true
  cd - >/dev/null
else
  rm -rf "$REPO_PATH"
  if gh repo clone "$REPO_FULL" "$REPO_PATH" -- --quiet 2>/dev/null; then
    : # clone succeeded
  else
    # Empty repo — initialize locally
    mkdir -p "$REPO_PATH"
    cd "$REPO_PATH"
    git init --quiet
    git remote add origin "https://github.com/${REPO_FULL}.git"
    cd - >/dev/null
  fi
fi

# Initialize repo structure if empty
REPO_PATH=$(get_local_repo_path)
cd "$REPO_PATH"

NEEDS_INIT=false
[[ ! -d "profiles/${PROFILE}" ]] && NEEDS_INIT=true

if $NEEDS_INIT; then
  info "Initializing repo structure with profile: ${PROFILE}"

  # Create directories
  mkdir -p "profiles/${PROFILE}/"{skills,agents,commands,hooks/scripts,hooks/config,hooks/sounds,rules,agent-memory,memory}
  mkdir -p "shared/"{skills,rules,agents}
  mkdir -p "global"

  # Create .sync-meta.json
  MACHINE_ID=$(get_machine_id)
  cat > ".sync-meta.json" <<METAEOF
{
  "version": "1.0",
  "created": "$(now_iso)",
  "profiles": {
    "${PROFILE}": {
      "created": "$(now_iso)",
      "last_push": null,
      "last_push_machine": null,
      "last_pull": null
    }
  },
  "machines": {
    "${MACHINE_ID}": {
      "first_seen": "$(now_iso)",
      "last_seen": "$(now_iso)"
    }
  }
}
METAEOF

  # Create placeholder files so directories are tracked
  echo "# Shared Claude Code Instructions" > "shared/CLAUDE.md"
  echo "# ${PROFILE} profile" > "profiles/${PROFILE}/README.md"

  # Create .gitignore
  cat > ".gitignore" <<'GIEOF'
# Machine-specific files (never sync)
settings.local.json
hooks-config.local.json
*.log
.DS_Store
GIEOF

  # Commit and push
  git add -A
  git commit -m "Initialize claudebase repo with profile: ${PROFILE}" --quiet
  git branch -M main
  git push -u origin main --quiet 2>/dev/null || {
    # If push fails, try setting up remote
    git push --set-upstream origin main --quiet
  }

  ok "Repo initialized with profile: ${PROFILE}"
else
  ok "Repo already initialized. Active profile: ${PROFILE}"
fi

cd - >/dev/null

ok "Setup complete!"
echo ""
echo -e "  Repo:    ${CYAN}https://github.com/${REPO_FULL}${NC}"
echo -e "  Profile: ${CYAN}${PROFILE}${NC}"
echo -e "  Machine: ${CYAN}$(get_machine_id)${NC}"
echo ""
echo -e "Next steps:"
echo -e "  ${BOLD}/cb:push${NC}   — Push current config to GitHub"
echo -e "  ${BOLD}/cb:pull${NC}   — Pull config from GitHub"
echo -e "  ${BOLD}/cb:status${NC} — Check sync status"
