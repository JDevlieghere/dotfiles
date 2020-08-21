#!/usr/bin/env bash

./swift/utils/build-script \
  --lldb \
  --release-debuginfo \
  --no-swift-stdlib-assertions \
  --skip-build-benchmarks \
  --skip-test-swift \
  --skip-test-cmark \
  $@
