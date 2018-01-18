#!/usr/bin/env bash

# Create install dir.
mkdir -p "$HOME/phacility" || exit 1

cd "$HOME/phacility" || exit 1
git clone https://github.com/phacility/libphutil.git
cd libphutil || exit 1
git checkout stable

cd "$HOME/phacility" || exit 1
git clone https://github.com/phacility/arcanist.git
cd arcanist || exit 1
git checkout stable

# Create symlink.
sudo ln -s "$HOME/phacility/arcanist/bin/arc" /usr/local/bin
