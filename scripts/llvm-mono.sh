#!/usr/bin/env bash

# Configures LLVM to be build and installed in the current directory.
# http://llvm.org/docs/GettingStarted.html#for-developers-to-work-with-a-git-monorepo
#
# Usage: ./llvm-mono.sh
#
# The script will create following directory structure:
# .
# ├── llvm-build
# └── llvm-project


export TOP_LEVEL_DIR=`pwd`
export GIT_SVN_DIR="$TOP_LEVEL_DIR/llvm-project/llvm/utils/git-svn/"
export PATH=$PATH:$GIT_SVN_DIR


# Clone
git clone https://github.com/llvm-project/llvm-project-20170507/ llvm-project

# Configure repo
cd llvm-project || exit 1
git config branch.master.rebase true
git config --add remote.origin.fetch +refs/notes/commits:refs/notes/commits
git fetch

# Create build dir
cd "$TOP_LEVEL_DIR" || exit 1
mkdir llvm-build && cd llvm-build

echo "Add the following directory to your \$PATH: $GIT_SVN_DIR"
