#!/usr/bin/env bash
# Detects the base branch and remote for the current repo.
# Outputs two lines: REMOTE=<remote> and BASE=<branch>
# Defaults: remote=github, base=master — falls back gracefully.

set -euo pipefail

# Detect remote: prefer "github", fall back to "origin", then first available
if git remote | grep -qx github; then
  REMOTE="github"
elif git remote | grep -qx origin; then
  REMOTE="origin"
else
  REMOTE=$(git remote | head -1)
fi

# Detect base branch: prefer master, fall back to main, then remote HEAD
if git rev-parse --verify master &>/dev/null; then
  BASE="master"
elif git rev-parse --verify main &>/dev/null; then
  BASE="main"
else
  BASE=$(git symbolic-ref "refs/remotes/${REMOTE}/HEAD" 2>/dev/null | sed "s|.*refs/remotes/[^/]*/||")
fi

if [ -z "$BASE" ]; then
  echo "ERROR: Could not determine base branch" >&2
  exit 1
fi

echo "REMOTE=$REMOTE"
echo "BASE=$BASE"
