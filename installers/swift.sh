#!/usr/bin/env bash

# Builds swift in the curren directory.
# .
# ├── build
# ├── clang
# ├── cmark
# ├── llvm
# └── swift
#
# Useful arguments to the build script include:
#   -i (build for iOS)
#   -r (build release with debug info)
#   -t (test after building)

export SWIFT_SOURCE_ROOT=$(pwd)
export SWIFT_BUILD_ROOT=$(pwd)/build

LLVM_BRANCH="swift-4.1-branch"
SWIFT_BRANCH="master"

git clone https://github.com/apple/swift-clang clang 2> /dev/null
git clone https://github.com/apple/swift-cmark cmark 2> /dev/null
git clone https://github.com/apple/swift-llvm llvm 2> /dev/null
git clone https://github.com/apple/swift 2> /dev/null

cd "$SWIFT_SOURCE_ROOT/clang" || exit
git checkout "$LLVM_BRANCH"
git pull --rebase

cd "$SWIFT_SOURCE_ROOT/llvm" || exit
git checkout "$LLVM_BRANCH"
git pull --rebase

cd "$SWIFT_SOURCE_ROOT/swift" || exit
git checkout "$SWIFT_BRANCH"
git pull --rebase

cd "$SWIFT_SOURCE_ROOT" || exit
./swift/utils/build-script "$@"
