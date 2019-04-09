#!/usr/bin/env bash

BUILD_DIR=/tmp/gn

# Clone
git clone https://gn.googlesource.com/gn "$BUILD_DIR"
cd "$BUILD_DIR" || exit 1

# Build
python build/gen.py
ninja -C out

# Install
sudo cp ./out/gn /usr/local/bin
