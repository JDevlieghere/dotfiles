#!/usr/bin/env bash

swift/utils/build-script \
  --lldb \
  --release-debuginfo \
  --test \
  -- \
  --skip-build-benchmarks \
  --no-swift-stdlib-assertions \
  --lldb-use-system-debugserver \
  --lldb-build-with-cmake \
  --skip-test-swift \
  --skip-test-cmark $@
