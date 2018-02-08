#!/usr/bin/env bash

# Builds swift in the current directory.
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
#   --skip-test-cmark (skip cmark tests)
#   --skip-test-swift (skip swift tests)

export SWIFT_SOURCE_ROOT=$(pwd)
export SWIFT_BUILD_ROOT=$(pwd)/build

SWIFT_CLANG_ROOT=$SWIFT_SOURCE_ROOT/clang
SWIFT_CMARK_ROOT=$SWIFT_SOURCE_ROOT/cmark
SWIFT_LLDB_ROOT=$SWIFT_SOURCE_ROOT/lldb
SWIFT_LLVM_ROOT=$SWIFT_SOURCE_ROOT/llvm
SWIFT_SWIFT_ROOT=$SWIFT_SOURCE_ROOT/swift

info() {
  printf "\033[00;34m$@\033[0m\n"
}

# Start in the root.
cd "$SWIFT_SOURCE_ROOT" || exit

# Clone if directories don't exist.
info "Cloning repositories"
git clone git@github.com:apple/swift-clang.git "$SWIFT_CLANG_ROOT"
git clone git@github.com:apple/swift-cmark.git "$SWIFT_CMARK_ROOT"
git clone git@github.com:apple/swift-lldb.git "$SWIFT_LLDB_ROOT"
git clone git@github.com:apple/swift-llvm.git "$SWIFT_LLVM_ROOT"
git clone git@github.com:apple/swift.git "$SWIFT_SWIFT_ROOT"

# Update checkout
"$SWIFT_SWIFT_ROOT/utils/update-checkout" --scheme=master --reset-to-remote

# Finally invoke build-script and forward all arguments.
info "Invoking build script"
"$SWIFT_SWIFT_ROOT/utils/build-script" "$@"
