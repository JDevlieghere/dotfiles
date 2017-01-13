#!/usr/bin/env bash

git clone git://github.com/ninja-build/ninja.git ~/ninja
cd ~/ninja
git checkout release
./configure.py --bootstrap
sudo cp ninja /usr/bin
