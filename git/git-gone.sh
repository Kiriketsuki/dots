#!/usr/bin/env bash
# git-gone: Remove local branches that have been deleted on remote
#
# Usage: git gone [--dry-run]
#
# This script prunes remote tracking branches and deletes local branches
# whose upstream branches no longer exist on the remote.

set -e

DRY_RUN=false

# Parse arguments
for arg in "$@"; do
  case $arg in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      echo "Usage: git gone [--dry-run]"
      echo ""
      echo "Remove local branches that have been deleted on remote."
      echo ""
      echo "Options:"
      echo "  --dry-run    Show what would be deleted without actually deleting"
      echo "  -h, --help   Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Prune remote tracking branches
echo "Pruning remote tracking branches..."
git fetch --prune

# Find branches whose upstream is gone
GONE_BRANCHES=$(git branch -vv | grep ': gone]' | awk '{print $1}' | sed 's/^[*+]*//')

if [ -z "$GONE_BRANCHES" ]; then
  echo "No gone branches to remove."
  exit 0
fi

echo ""
echo "The following branches will be removed:"
echo "$GONE_BRANCHES"
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "(Dry run - no branches were actually deleted)"
  exit 0
fi

# Confirm deletion
read -p "Delete these branches? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

# Delete the branches
echo "$GONE_BRANCHES" | xargs -r git branch -D

echo ""
echo "✓ Removed $(echo "$GONE_BRANCHES" | wc -l) branch(es)."
