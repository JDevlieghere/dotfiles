#!/usr/bin/env bash

# Clone the swift repository.
git clone git@github.com:apple/swift.git

# Use the update-checkout script to clone everyting else.
python swift/utils/update-checkout --scheme master --clone-with-ssh
