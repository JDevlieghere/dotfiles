#!/usr/bin/env bash

BUILD_DIR=/tmp/ninja

# Clone
git clone https://github.com/ninja-build/ninja.git "$BUILD_DIR"
cd "$BUILD_DIR" || exit 1
git checkout release

# Build
python3 ./configure.py --bootstrap

# Install
sudo cp ninja /usr/local/bin
