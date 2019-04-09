#!/usr/bin/env bash

sudo apt update
sudo apt upgrade

# Essentials
sudo apt install -y \
    afl \
    arc-theme \
    build-essential \
    curl \
    doxygen \
    dtrx \
    exuberant-ctags \
    ffmpeg \
    fish \
    gdb \
    git \
    gnupg \
    gparted \
    graphviz \
    htop \
    lcov \
    lldb \
    lm-sensors \
    nasm \
    neofetch \
    nfs-common \
    nodejs \
    npm \
    python \
    python-pip \
    ranger \
    re2c \
    scrot \
    shellcheck \
    silversearcher-ag \
    tig \
    tig \
    tmux \
    tree \
    unrar \
    vbindiff \
    weechat-curses weechat-plugins \
    xz-utils

# Pass any argument to this script for a "full" install
if [ -n "$1" ]; then
    # Developer packages
    sudo apt install -y \
        bzip2 \
        libatk1.0-dev \
        libbonoboui2-dev \
        libboost-all-dev \
        libcairo2-dev \
        libedit-dev \
        libgnome2-dev \
        libgnomeui-dev \
        libgtk2.0-dev \
        liblzma-dev \
        libncurses5-dev \
        libsqlite3-dev \
        libx11-dev \
        libxml2-dev \
        libxpm-dev \
        libxt-dev \
        python-dev \
        python2.7-dev \
        ruby-dev \
        subversion \
        swig \
        uuid-dev

    # OpenVPN
    sudo apt install -y \
        openvpn \
        network-manager-openvpn \
        network-manager-openvpn-gnome

    # xmonad
    sudo apt install -y \
        compton \
        dmenu \
        feh \
        hsetroot \
        scrot \
        xmobar \
        xmonad

    # Vim (from source)
    # https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
    sudo apt remove vim vim-runtime gvim
    which vim
    if [ $? != 0 ] ; then
        git clone https://github.com/vim/vim.git ~/vim
        cd ~/vim || exit 1
        ./configure \
            --with-features=huge \
            --enable-multibyte \
            --enable-rubyinterp \
            --enable-pythoninterp \
            --with-python-config-dir=/usr/lib/python2.7/config \
            --enable-perlinterp \
            --enable-luainterp \
            --enable-gui=gtk2 --enable-cscope --prefix=/usr
        make -j VIMRUNTIMEDIR=/usr/share/vim/vim81
        sudo make install

        sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
        sudo update-alternatives --set editor /usr/bin/vim
        sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
        sudo update-alternatives --set vi /usr/bin/vim
    fi
fi

# Cleanup
sudo apt autoremove
sudo apt autoclean
