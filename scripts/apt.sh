#!/usr/bin/env bash

sudo apt update
sudo apt upgrade

# Basics
sudo apt install -y \
    build-essential \
    clang-format \
    cmake \
    curl \
    fd-find \
    fish \
    fzf \
    git \
    gnupg \
    graphviz \
    htop \
    hyperfine \
    neovim \
    pandoc \
    re2c \
    ripgrep \
    swig \
    tmux \
    vim \
    tree

# Developer packages
sudo apt install -y \
    bzip2 \
    libboost-all-dev \
    libedit-dev \
    liblzma-dev \
    libncurses5-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxpm-dev \
    libxt-dev \
    ncurses-dev \
    python3-dev \
    uuid-dev

# Cleanup
sudo apt autoremove
sudo apt autoclean
