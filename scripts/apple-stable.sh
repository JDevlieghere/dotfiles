#!/usr/bin/env bash

set -euo pipefail

readonly stable_repo="apple/llvm-project"

stable_branch=""
stable_mnemonic=""
commits=()

for i in "$@"
do
    case $i in
        next)
            stable_branch="next"
            stable_mnemonic="next"
            shift
            ;;
        bastille)
            stable_branch="apple/stable/20200714"
            stable_mnemonic="bastille"
            shift
            ;;
        ganymede)
            stable_branch="apple/stable/20210107"
            stable_mnemonic="ganymede"
            shift
            ;;
        fbi)
            stable_branch="stable/20210726"
            stable_mnemonic="FBI"
            shift
            ;;
        austria)
            stable_branch="stable/20211026"
            stable_mnemonic="austria"
            shift
            ;;
        rome)
            stable_branch="stable/20220421"
            stable_mnemonic="rome"
            shift
            ;;
        rebranch)
            stable_branch="stable/20221013"
            stable_mnemonic="rebranch"
            shift
            ;;
        5.6)
            stable_branch="swift/release/5.6"
            stable_mnemonic="5.6"
            shift
            ;;
        5.7)
            stable_branch="swift/release/5.7"
            stable_mnemonic="5.7"
            shift
            ;;
        *)
            commits+=("$i")
            shift
            ;;
    esac
done

if [ -z "$stable_branch" ]
then
    echo "Unknown branch/mnemonic"
    exit 1
fi

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

function join { local IFS='+'; echo "$*"; }

target_branch="🍒/$stable_mnemonic/$(join "${commits[@]}")"
git checkout -b "$target_branch"

for commit in "${commits[@]}"
do
    git cherry-pick -x $commit
done

# Use GitHub CLI to create a PR against the correct repository.
gh pr create --fill --repo "apple/llvm-project" --base "$stable_branch" --web
