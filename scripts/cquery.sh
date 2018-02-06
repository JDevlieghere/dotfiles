#!/usr/bin/env bash

# Build the cquery low-latency language server.
#
# https://github.com/cquery-project/cquery

# Clone
git clone https://github.com/jacobdufault/cquery --single-branch --depth=1
cd cquery || exit 1
git submodule update --init

# Build
./waf configure   # --variant=debug if you want to report issues.
./waf build       # --variant=debug . Yes, it is duplicated here

# Install
cp build/release/bin/cquery /usr/local/bin
