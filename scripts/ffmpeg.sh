#!/usr/bin/env bash

# Build ffmpeg on Ubuntu with nVidia/CUDA hardware acceleration.

# Clone source
if [ ! -d "ffmpeg" ]; then
  git clone git://source.ffmpeg.org/ffmpeg.git
fi

cd ffmpeg || exit 1

# Get dependencies
sudo apt install \
  libass-dev \
  libfdk-aac-dev \
  libmp3lame-dev \
  libopus-dev \
  libvorbis-dev \
  libvpx-dev \
  libx264-dev \
  libx265-dev \
  yasm

# Configure
./configure \
  --enable-nonfree \
  --enable-gpl \
  --enable-libass \
  --enable-libfdk-aac \
  --enable-libfreetype \
  --enable-libmp3lame \
  --enable-libopus \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --disable-shared \
  --enable-nvenc \
  --enable-cuda \
  --enable-cuvid \
  --enable-libnpp

# Compile & Install
make -j
sudo make install
