#!/usr/bin/env bash

set -euo pipefail

# This changes only a few times a year.
readonly stable_repo="apple/llvm-project"
readonly stable_branch="apple/stable/20210107"
readonly stable_mnemonic="ganymede"

# Make sure we have GitHub CLI installed.
if ! hash gh 2>/dev/null
then
    echo "Could not find GitHub CLI (gh)"
    exit 1
fi

# Make sure we have upstream llvm as a remote.
if ! git ls-remote --exit-code llvm > /dev/null; then
    git remote add llvm git@github.com:llvm/llvm-project.git
    git remote set-url --push llvm /dev/null
fi

git fetch -q --multiple origin llvm
git checkout -q origin/$stable_branch

for commit in "$@"
do
    git cherry-pick -x $commit
done

function join { local IFS='+'; echo "$*"; }

target_branch="🍒/$stable_mnemonic/$(join "$@")"
git checkout -b "$target_branch"

# Use GitHub CLI to create a PR against the correct repository.
gh pr create --fill  --repo "apple/llvm-project" --base "$stable_branch" --web
