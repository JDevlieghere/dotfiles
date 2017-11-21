#!/usr/bin/env bash

# Configures LLVM to be build and installed in the current directory.
# http://llvm.org/docs/GettingStarted.html#for-developers-to-work-with-a-git-monorepo
#
# Usage: ./llvm-mono.sh [projects] [cmake build type]
#
# The script will create following directory structure:
# .
# ├── llvm-build
# ├── llvm-install
# └── llvm-project

if [ -z "$1" ]; then
    PROJECTS="clang;clang-tools-extra;compiler-rt"
else
    PROJECTS="$1"
fi

export TOP_LEVEL_DIR=`pwd`
export PATH=$PATH:$TOP_LEVEL_DIR/llvm-project/llvm/utils/git-svn/

git clone https://github.com/llvm-project/llvm-project-20170507/ llvm-project
cd llvm-project || exit 1
git config branch.master.rebase true

cd "$TOP_LEVEL_DIR" || exit 1
mkdir -p llvm-install || exit 1
mkdir -p llvm-build || exit 1

cd llvm-build || exit 1
cmake ../llvm-project/llvm \
    -G Ninja \
    -DLLVM_ENABLE_PROJECTS="$PROJECTS" \
    -DCMAKE_INSTALL_PREFIX="$TOP_LEVEL_DIR/llvm-install" \
    -DCMAKE_BUILD_TYPE="RelWithDebInfo" \
    -DBUILD_SHARED_LIBS=ON
