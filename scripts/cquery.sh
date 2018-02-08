#!/usr/bin/env bash

# Clone
git clone https://github.com/jacobdufault/cquery /tmp/cquery --single-branch --depth=1
cd /tmp/cquery || exit 1
git submodule update --init

# Build
./waf configure   # --variant=debug if you want to report issues.
./waf build       # --variant=debug . Yes, it is duplicated here

# Install
sudo cp build/release/bin/cquery /usr/local/bin
