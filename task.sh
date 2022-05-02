#!/bin/bash

# This script was written with the following assumptions:
#   * you have two remotes: `upstream` and `origin`.
#   * you only ever push to `origin`


# For most projects this would be master, but dev is our main branch
DEFAULT_BRANCH="master"

# WARNING: I have not tested whether you can set this to origin and just have a single remote
UPSTREAM_REMOTE="https://github.com/venkatareddybandi9999/anoop.git"

if [ -z "$(git remote | grep $UPSTREAM_REMOTE)" ]; then
  echo "Unable to find remote $UPSTREAM_REMOTE"
  exit 1
fi

if [ ! -z "$(git status --porcelain --untracked-files=no)" ]; then
  echo "Commit or remove your changes first"
  git status
  exit 1
fi

# if any of these commands fail, the whole process should abort
set -e
git remote update
git checkout $DEFAULT_BRANCH
git pull --ff-only $UPSTREAM_REMOTE $DEFAULT_BRANCH
set +e

# Remove local origin/BRANCH references to branches that have already been cleaned up
git remote prune origin

TARGET="$UPSTREAM_REMOTE/$DEFAULT_BRANCH"
# This uses `sed` instead of `cut` to remain compatible with branches that include slashes. ex: origin/asa/my-feature
BRANCHES=$(git branch --remote --merged $TARGET --list "origin/*" | sed s/"\s*origin\/"//g | grep --extended-regexp -v "(HEAD|dev|master)$")
echo "===== Finding remote branches that have merged into $TARGET"

if [ ! -z "$BRANCHES" ]; then
  PUSH="git push origin --no-verify"
  for B in $BRANCHES; do
    PUSH="$PUSH :$B"
  done
  echo "$PUSH"
fi

# The currently checked out branch is prefixed with a *. 
# If it isn't removed, then it ends up getting expanded by bash.
BRANCHES=$(git branch --merged $TARGET | grep -v '^\*' | grep --extended-regexp -v "(HEAD|dev|master)$")
echo "===== Finding local branches that have merged into $TARGET"
for B in $BRANCHES; do
  echo "git branch --delete $B"
done
