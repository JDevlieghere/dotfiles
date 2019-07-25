#!/usr/bin/env bash

swift/utils/build-script \
  --cmake-c-launcher `which sccache` \
  --cmake-cxx-launcher `which sccache` \
  --lldb \
  --release-debuginfo \
  --test \
  -- \
  --skip-build-benchmarks \
  --no-swift-stdlib-assertions \
  --lldb-use-system-debugserver \
  --skip-test-swift \
  --skip-test-cmark $@
