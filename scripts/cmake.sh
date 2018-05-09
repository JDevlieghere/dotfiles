#!/usr/bin/env bash

BUILD_DIR=/tmp/cmake

# Clone
git clone https://github.com/Kitware/CMake.git "$BUILD_DIR"
cd "$BUILD_DIR" || exit 1
git checkout release

# Build
./bootstrap
make -j

# Install
sudo make install
