#!/usr/bin/env bash

if [ -z "$1" ]; then
  echo "Usage: gcc.sh [version]"
  exit 1
fi

VERSION="gcc-$1"
ROOT=$(pwd)

# Dependencies
sudo apt install libmpfr-dev libgmp3-dev libmpc-dev flex bison

wget "http://ftp.gnu.org/gnu/gcc/$VERSION/$VERSION.tar.gz"
tar -zxvf "$VERSION.tar.gz"

cd "$VERSION" || exit 1
mkdir build
mkdir install

cd build || exit 1

../configure --disable-checking --enable-languages=c,c++ \
  --enable-multiarch --enable-shared --enable-threads=posix \
  --program-suffix=6.3 --with-gmp=/usr/local/lib --with-mpc=/usr/lib \
  --with-mpfr=/usr/lib --without-included-gettext --with-system-zlib \
  --with-tune=generic --disable-multilib \
  --prefix="$ROOT/$VERSION/install"

make -j
make install
