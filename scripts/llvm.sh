#!/usr/bin/env bash

# Builds LLVM, clang and some projects (see below) in the current directory.
# .
# ├── build
# ├── install
# └── llvm

ROOT=$(pwd)
USER="jdevlieghere"

function init {
    local DIR=$1
    local PROJECT=$2

    cd "$DIR" || return

    # Prevent non-linear history
    git config branch.master.rebase true

    # Set-up git svn
    git svn init "https://llvm.org/svn/llvm-project/$PROJECT/trunk" --username="$USER"
    git config svn-remote.svn.fetch :refs/remotes/origin/master
    git svn rebase -l > /dev/null
}

# llvm
git clone https://llvm.org/git/llvm.git
init "$ROOT/llvm" "llvm"

# clang
cd "$ROOT/llvm/tools" || exit
git clone https://llvm.org/git/clang.git
init "$ROOT/llvm/tools/clang" "cfe"

# clang-tools-extra
cd "$ROOT/llvm/tools/clang/tools" || exit
git clone https://llvm.org/git/clang-tools-extra.git extra
init "$ROOT/llvm/tools/clang/tools/extra" "clang-tools-extra"

# compiler-rt
cd "$ROOT/llvm/projects" || exit
git clone https://llvm.org/git/compiler-rt.git
init "$ROOT/llvm/projects/compiler-rt" "compiler-rt"

# libcxx
if [[ -n "$LIBCXX" ]]; then
    cd "$ROOT/llvm/projects" || exit
    git clone http://llvm.org/git/libcxx.git
    git clone http://llvm.org/git/libcxxabi.git
fi

# test-suite
if [[ -n "$TESTSUITE" ]]; then
    cd "$ROOT/llvm/projects" || exit
    git clone http://llvm.org/git/test-suite.git
fi

# Create build and install dirs
cd "$ROOT" || exit
mkdir -p build
mkdir -p install

# Run Cmake
cd build || exit
cmake ../llvm \
    -G Ninja \
    -DCMAKE_INSTALL_PREFIX="../install" \
    -DCMAKE_BUILD_TYPE="RelWithDebInfo" \
    -DBUILD_SHARED_LIBS=On \
    -DCOMPILER_RT_DEBUG=On \
    -DLLVM_INCLUDE_TESTS=On \
    -DLLVM_ENABLE_ASSERTIONS=On

# Run Ninja
ninja
