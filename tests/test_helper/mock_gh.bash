#!/usr/bin/env bash
# mock_gh.bash — Fake gh CLI for testing

# Log all invocations
echo "$*" >> "$MOCK_GH_CALLS_LOG"

case "$1" in
  auth)
    if [[ "$2" == "status" ]]; then
      if [[ "$MOCK_GH_AUTHENTICATED" == "true" ]]; then
        exit 0
      else
        echo "You are not logged into any GitHub hosts." >&2
        exit 1
      fi
    fi
    ;;
  config)
    # `gh config get -h github.com git_protocol` → read MOCK_GH_PROTOCOL.
    # Unset env var produces empty output (matches real gh when no value set).
    if [[ "$2" == "get" ]]; then
      for arg in "$@"; do
        if [[ "$arg" == "git_protocol" ]]; then
          [[ -n "$MOCK_GH_PROTOCOL" ]] && echo "$MOCK_GH_PROTOCOL"
          exit 0
        fi
      done
    fi
    exit 0
    ;;
  api)
    if [[ "$2" == "user" ]]; then
      if [[ "$3" == "-q" && "$4" == ".login" ]]; then
        echo "$MOCK_GH_USER"
      else
        echo "{\"login\": \"$MOCK_GH_USER\"}"
      fi
      exit 0
    fi
    ;;
  repo)
    case "$2" in
      view)
        # Detect a `--json isEmpty` query. ensure-repo.sh uses this to
        # distinguish an intentionally empty remote from a real clone
        # failure, so the mock needs to honor MOCK_GH_REPO_EMPTY here.
        # (No `local` — this script runs at top level, not in a function.)
        is_empty_query=false
        for arg in "$@"; do
          [[ "$arg" == "isEmpty" ]] && is_empty_query=true
        done
        if [[ "$is_empty_query" == "true" ]]; then
          if [[ "$MOCK_GH_REPO_EXISTS" != "true" ]]; then
            echo "Could not resolve to a Repository" >&2
            exit 1
          fi
          echo "${MOCK_GH_REPO_EMPTY:-false}"
          exit 0
        fi
        # Plain existence check
        if [[ "$MOCK_GH_REPO_EXISTS" == "true" ]]; then
          exit 0
        else
          echo "Could not resolve to a Repository" >&2
          exit 1
        fi
        ;;
      create)
        exit 0
        ;;
      clone)
        if [[ "$MOCK_GH_CLONE_FAILS" == "true" ]]; then
          echo "Cloning into '$3'..." >&2
          echo "Host key verification failed." >&2
          exit 1
        fi
        if [[ -n "$MOCK_GH_CLONE_SOURCE" ]]; then
          # $3 is the repo name, $4 is the destination (or $3 could be dest)
          # gh repo clone <name> <dest> -- find the dest arg
          local dest=""
          shift 2  # skip "repo clone"
          local repo_arg="$1"; shift
          dest="$1"
          if [[ -n "$dest" ]]; then
            git clone "$MOCK_GH_CLONE_SOURCE" "$dest" 2>/dev/null
            exit $?
          else
            git clone "$MOCK_GH_CLONE_SOURCE" 2>/dev/null
            exit $?
          fi
        else
          exit 0
        fi
        ;;
    esac
    ;;
esac

# Default: exit 0 for unknown commands
exit 0
