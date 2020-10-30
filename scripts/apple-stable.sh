#!/usr/bin/env bash

set -euo pipefail

readonly repo="apple/llvm-project"

# This changes only a few times a year.
readonly stable_branch="apple/stable/20200714"
readonly stable_mnemonic="bastille"

# Make sure we have upstream llvm as a remote.
git ls-remote --exit-code llvm > /dev/null
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

# Use GitHub CLI to create a PR against the correct repo.
gh pr create --fill --base "$stable_branch"  --repo "$repo" --web
