#!/usr/bin/env bash

# Builds LLVM, clang and clang-tools extra in the curren directory.
# .
# ├── build
# ├── install
# └── llvm


# LLVM Configuration
if [ -z "$1" ]; then
    TYPE="Debug"
else
    TYPE="Release"
fi

ROOT=$(pwd)

# LLVM
git clone http://llvm.org/git/llvm.git
cd "$ROOT/llvm" || exit

# Compiler-RT
cd "$ROOT/llvm/projects" || exit
git clone http://llvm.org/git/compiler-rt.git

# Clang
cd "$ROOT/llvm/tools" || exit
git clone http://llvm.org/git/clang.git

# Clang-tools-extra
cd "$ROOT/llvm/tools/clang/tools" || exit
git clone http://llvm.org/git/clang-tools-extra.git extra

# Create build folder
cd "$ROOT" || exit
mkdir build || exit
cd build || exit
cmake -G Ninja ../llvm -DCMAKE_INSTALL_PREFIX="$ROOT/install" -DCMAKE_BUILD_TYPE="$TYPE"
