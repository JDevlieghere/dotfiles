#!/usr/bin/env bash

# Creates LLVM repository structure for git-svn.
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

if [ -z "$1" ]; then
    # clang
    cd "$ROOT/llvm/tools" || exit
    git clone https://llvm.org/git/clang.git
    init "$ROOT/llvm/tools/clang" "cfe"

    # clang-tools-extra
    cd "$ROOT/llvm/tools/clang/tools" || exit
    git clone https://llvm.org/git/clang-tools-extra.git extra
    init "$ROOT/llvm/tools/clang/tools/extra" "clang-tools-extra"

    # lldb
    cd "$ROOT/llvm/tools" || exit
    git clone https://llvm.org/git/lldb.git
    init "$ROOT/llvm/tools/lldb" "lldb"

    # compiler-rt
    cd "$ROOT/llvm/projects" || exit
    git clone https://llvm.org/git/compiler-rt.git
    init "$ROOT/llvm/projects/compiler-rt" "compiler-rt"

    # libcxx
    cd "$ROOT/llvm/projects" || exit
    git clone http://llvm.org/git/libcxx.git
    git clone http://llvm.org/git/libcxxabi.git
fi

# Create build and install dirs
cd "$ROOT" || exit
mkdir -p build
mkdir -p install
