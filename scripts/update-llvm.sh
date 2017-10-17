#!/usr/bin/env bash

# Automatically updates and rebuilds LLVM. Particularly convenient for setting
# a cron job. The first argument is the root where we should start looking for
# repositories and build folders.

ROOT="$1"
cd "$ROOT"

for i in $(find . -type d -name ".git"); do
    cd $(dirname "$i")
    git pull --rebase
    cd "$ROOT"
done

for i in $(find . -type f -name "CMakeCache.txt"); do
    cd $(dirname "$i")
    time cmake --build .
    cd "$ROOT"
done
