#!/usr/bin/env bash
# git-track-all: Create local tracking branches for all remote branches
#
# Usage: git track-all [--dry-run] [remote]
#
# This script fetches from remote and creates local tracking branches
# for all remote branches that don't have a local counterpart yet.

set -e

DRY_RUN=false
REMOTE="origin"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      echo "Usage: git track-all [--dry-run] [remote]"
      echo ""
      echo "Create local tracking branches for all remote branches."
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would be created without actually creating"
      echo "  -h, --help   Show this help message"
      echo ""
      echo "Arguments:"
      echo "  remote       Remote name (default: origin)"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
    *)
      REMOTE="$1"
      shift
      ;;
  esac
done

# Fetch from remote
echo "Fetching from '$REMOTE'..."
git fetch "$REMOTE"

# Get list of remote branches
REMOTE_BRANCHES=$(git branch -r | grep "^[[:space:]]*$REMOTE/" | grep -v "HEAD" | sed "s|^[[:space:]]*$REMOTE/||")

if [ -z "$REMOTE_BRANCHES" ]; then
  echo "No remote branches found on '$REMOTE'."
  exit 0
fi

# Get list of local branches
LOCAL_BRANCHES=$(git branch | sed 's/^[*[:space:]]*//')

# Find branches that don't exist locally
NEW_BRANCHES=""
while IFS= read -r branch; do
  if ! echo "$LOCAL_BRANCHES" | grep -q "^${branch}$"; then
    NEW_BRANCHES="${NEW_BRANCHES}${branch}"$'\n'
  fi
done <<< "$REMOTE_BRANCHES"

# Remove trailing newline
NEW_BRANCHES=$(echo "$NEW_BRANCHES" | sed '/^$/d')

if [ -z "$NEW_BRANCHES" ]; then
  echo "All remote branches already have local tracking branches."
  exit 0
fi

echo ""
echo "The following local tracking branches will be created:"
echo "$NEW_BRANCHES"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "(Dry run - no branches were actually created)"
  exit 0
fi

# Create tracking branches
BRANCH_COUNT=0
while IFS= read -r branch; do
  echo "Creating: $branch -> $REMOTE/$branch"
  git branch --track "$branch" "$REMOTE/$branch"
  ((BRANCH_COUNT++))
done <<< "$NEW_BRANCHES"

echo ""
echo "✓ Created $BRANCH_COUNT tracking branch(es)."
