#!/usr/bin/env bash

# Get the latest release
git clone https://github.com/Kitware/CMake.git ~/CMake
cd ~/CMake || exit 1
git checkout release

# Install CMake
./bootstrap
make -j
sudo make install
