#!/usr/bin/env bash

# Get the latest release
git clone https://github.com/Kitware/CMake.git ~/CMake
cd ~/CMake
git checkout release

# Install CMake
./bootstrap
make
sudo make install
