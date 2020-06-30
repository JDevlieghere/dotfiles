#!/usr/bin/env bash

./swift/utils/build-script \
  --lldb \
  --release-debuginfo \
  --skip-build-benchmarks \
  --no-swift-stdlib-assertions \
  --lldb-use-system-debugserver \
  --skip-test-swift \
  --skip-test-cmark \
  $@
