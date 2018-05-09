#!/usr/bin/env bash

BUILD_DIR=/tmp/alacritty

# Clone the repository.
git clone https://github.com/jwilm/alacritty.git "$BUILD_DIR"
cd "$BUILD_DIR"

# Make sure we have the right Rust compiler.
rustup override set stable
rustup update stable

# Build and install.
if [ "$(uname)" == "Darwin" ]; then
  make app
  sudo cp -r target/release/osx/Alacritty.app /Applications/
else
  cargo build --release
  sudo cp target/release/alacritty /usr/local/bin
fi
