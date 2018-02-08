#!/usr/bin/env bash

# Clone
git clone https://github.com/Kitware/CMake.git /tmp/cmake
cd /tmp/cmake || exit 1
git checkout release

# Build
./bootstrap
make -j

# Install
sudo make install
