#!/usr/bin/env bash

# Configures LLVM to be build and installed in the current directory.
# http://llvm.org/docs/GettingStarted.html#for-developers-to-work-with-a-git-monorepo
#
# Usage: ./llvm-mono.sh [projects] [cmake build type]
#
# The script will create following directory structure:
# .
# ├── build
# ├── install
# └── llvm-project

# CMake Build Type
if [ -z "$1" ]; then
    PROJECTS="clang;clang-tools-extra;compiler-rt"
else
    PROJECTS="$1"
fi

TOP_LEVEL_DIR=$(pwd)

export TOP_LEVEL_DIR="$TOP_LEVEL_DIR"
export PATH=$PATH:$TOP_LEVEL_DIR/llvm-project/llvm/utils/git-svn/

# Clone momorepo
git clone https://github.com/llvm-project/llvm-project-20170507/ llvm-project
cd llvm-project || exit 1
git config branch.master.rebase true

# Create folders
cd "$TOP_LEVEL_DIR" || exit 1
mkdir -p install || exit 1
mkdir -p build || exit 1

# Run CMake
cd build || exit 1
cmake ../llvm-project/llvm \
    -G Ninja \
    -DLLVM_ENABLE_PROJECTS="$PROJECTS" \
    -DCMAKE_INSTALL_PREFIX="$TOP_LEVEL_DIR/install" \
    -DCMAKE_BUILD_TYPE="RelWithDebInfo" \
    -DBUILD_SHARED_LIBS=ON
