#!/usr/bin/env bash

set -e

PCRE_DIR=/tmp/pcre
SWIG_DIR=/tmp/swig

# Start clean
rm -rf "$PCRE_DIR"
rm -rf "$SWIG_DIR"

# PCRE
mkdir -p "$PCRE_DIR"
cd "$PCRE_DIR"
curl -O https://ftp.pcre.org/pub/pcre/pcre-8.44.zip
unzip -oq pcre-8.44.zip
cd pcre-8.44
./configure --prefix=/usr/local
make -j
sudo make install

# SWIG
git clone https://github.com/swig/swig.git "$SWIG_DIR"
cd "$SWIG_DIR"
./autogen.sh
./configure --prefix=/usr/local
make -j
sudo make install
