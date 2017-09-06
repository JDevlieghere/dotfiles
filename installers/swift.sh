#!/usr/bin/env bash

# Builds swift in the curren directory.
# .
# ├── build
# ├── clang
# ├── cmark
# ├── llvm
# └── swift

# Optional environment variables that affect the behavior of this script:
#   LLVM_BRANCH (checkout the given LLVM and clang branch)
#   PULL        (pull all repositories)
#
# Useful arguments to the build script include:
#   -i (build for iOS)
#   -r (build release with debug info)
#   -t (test after building)

export SWIFT_SOURCE_ROOT=$(pwd)
export SWIFT_BUILD_ROOT=$(pwd)/build

SWIFT_CLANG_ROOT=$SWIFT_SOURCE_ROOT/clang
SWIFT_LLVM_ROOT=$SWIFT_SOURCE_ROOT/llvm
SWIFT_SWIFT_ROOT=$SWIFT_SOURCE_ROOT/swift
SWIFT_CMARK_ROOT=$SWIFT_SOURCE_ROOT/cmark

info() {
  printf "\033[00;34m$@\033[0m\n"
}

checkout() {
  local ROOT=$1
  local BRANCH=$2

  cd "$ROOT" || return 1
  git checkout "$BRANCH"
  cd "$SWIFT_SOURCE_ROOT"
}

pull() {
  local ROOT=$1

  cd "$ROOT" || return 1
  git pull --rebase
  cd "$SWIFT_SOURCE_ROOT"
}

# Start in the root.
cd "$SWIFT_SOURCE_ROOT" || exit

# Clone if directories don't exist.
git clone https://github.com/apple/swift-clang "$SWIFT_CLANG_ROOT" 2> /dev/null && info "Cloning clang"
git clone https://github.com/apple/swift-cmark "$SWIFT_CMARK_ROOT" 2> /dev/null && info "Cloning cmark"
git clone https://github.com/apple/swift-llvm "$SWIFT_LLVM_ROOT" 2> /dev/null && info "Cloning llvm"
git clone https://github.com/apple/swift "$SWIFT_SWIFT_ROOT" 2> /dev/null && info "Cloning swift"

# Checkout LLVM/clang branch if environment variable LLVM_BRANCH is set.
if [ -n "$LLVM_BRANCH" ]; then
  info "Checking out $LLVM_BRANCH"
  checkout "$SWIFT_CLANG_ROOT" "$LLVM_BRANCH"
  checkout "$SWIFT_LLVM_ROOT" "$LLVM_BRANCH"
fi

# Pull all repositories if environment variable PULL is set.
if [ -n "$PULL" ]; then
  info "Pulling repositories"
  pull "$SWIFT_CLANG_ROOT"
  pull "$SWIFT_LLVM_ROOT"
  pull "$SWIFT_CMARK_ROOT"
  pull "$SWIFT_SWIFT_ROOT"
fi

# Finally invoke build-script and forward all arguments.
info "Invoking build script"
"$SWIFT_SWIFT_ROOT/utils/build-script" "$@"
