#!/usr/bin/env bash

# Builds LLVM, clang and clang-tools extra in the curren directory.
# .
# ├── build
# ├── install
# └── llvm


# LLVM Build Type
if [ -z "$1" ]; then
    TYPE="Debug"
else
    TYPE="$1"
fi

# Without a second argument only LLVM and clang will be built.
if [ -z "$2" ]; then
    ALL=false
else
    ALL=true
fi

ROOT=$(pwd)

if [[ ! -e llvm ]]; then
    # llvm
    git clone http://llvm.org/git/llvm.git
    cd "$ROOT/llvm" || exit

    # clang
    cd "$ROOT/llvm/tools" || exit
    git clone http://llvm.org/git/clang.git

    if [ "$ALL" = true ]; then
        # compiler-RT
        cd "$ROOT/llvm/projects" || exit
        git clone http://llvm.org/git/compiler-rt.git

        # libcxx and libcxxabi
        cd "$ROOT/llvm/projects" || exit
        git clone http://llvm.org/git/libcxx.git
        git clone http://llvm.org/git/libcxxabi.git

        # lld
        cd "$ROOT/llvm/tools" || exit
        git clone http://llvm.org/git/lld.git


        # clang-tools-extra
        cd "$ROOT/llvm/tools/clang/tools" || exit
        git clone http://llvm.org/git/clang-tools-extra.git extra
    fi
fi

# Create build folder
cd "$ROOT" || exit
mkdir -p build
cd build || exit

# Run Cmake
cmake ../llvm \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="$ROOT/install" \
    -DCMAKE_BUILD_TYPE="$TYPE" \
    -DBUILD_SHARED_LIBS=ON \
    -DLLVM_TARGETS_TO_BUILD="ARM;X86"
