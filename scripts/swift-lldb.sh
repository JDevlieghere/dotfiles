#!/usr/bin/env bash

export SKIP_XCODE_VERSION_CHECK=1
./swift/utils/build-script \
  --lldb \
  --release-debuginfo \
  --no-swift-stdlib-assertions \
  --skip-build-benchmarks \
  --skip-test-swift \
  --skip-test-cmark \
  --skip-early-swift-driver \
  $@
