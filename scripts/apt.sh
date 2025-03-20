#!/usr/bin/env bash

sudo add-apt-repository ppa:neovim-ppa/unstable

sudo apt update
sudo apt upgrade

# Developer packages
sudo apt install -y \
    bzip2 \
    libboost-all-dev \
    libedit-dev \
    liblzma-dev \
    libncurses5-dev \
    libpcre3-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxpm-dev \
    libxt-dev \
    ncurses-dev \
    python3-dev \
    uuid-dev

# Basics
sudo apt install -y \
    build-essential \
    clang-format \
    cmake \
    curl \
    fd-find \
    ffmpeg \
    fish \
    fzf \
    git \
    gnupg \
    graphviz \
    htop \
    hyperfine \
    lld \
    lldb \
    neovim \
    ninja-build \
    pandoc \
    re2c \
    ripgrep \
    shellcheck \
    software-properties-common \
    swig \
    tmux \
    vim \
    tree

# Cleanup
sudo apt autoremove
sudo apt autoclean
