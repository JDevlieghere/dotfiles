#!/usr/bin/env bash

# Configures LLVM to be build and installed in the current directory.
# http://llvm.org/docs/GettingStarted.html#for-developers-to-work-with-a-git-monorepo
#
# Usage: ./llvm-mono.sh
#
# The script will create following directory structure:
# .
# ├── clang-build
# ├── lldb-build
# ├── llvm-build
# └── llvm-project


export TOP_LEVEL_DIR=`pwd`
export PATH=$PATH:$TOP_LEVEL_DIR/llvm-project/llvm/utils/git-svn/

git clone https://github.com/llvm-project/llvm-project-20170507/ llvm-project

cd llvm-project || exit 1
git config branch.master.rebase true
git config --add remote.origin.fetch +refs/notes/commits:refs/notes/commits
git fetch

cd "$TOP_LEVEL_DIR" || exit 1
mkdir llvm-build && cd llvm-build
cmake -GNinja ../llvm-project/llvm

cd "$TOP_LEVEL_DIR" || exit 1
mkdir clang-build && cd clang-build
cmake -GNinja ../llvm-project/llvm -DLLVM_ENABLE_PROJECTS="clang;clang-tools-extra;compiler-rt"

cd "$TOP_LEVEL_DIR" || exit 1
mkdir lldb-build && cd lldb-build
cmake -GNinja ../llvm-project/llvm -DLLVM_ENABLE_PROJECTS=lldb
