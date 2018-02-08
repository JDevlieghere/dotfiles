#!/usr/bin/env bash

# Clone
git clone git://github.com/ninja-build/ninja.git /tmp/ninja
cd /tmp/ninja || exit 2
git checkout release

# Build
./configure.py --bootstrap

# Install
sudo cp ninja /usr/local/bin
