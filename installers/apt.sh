sudo apt update
sudo apt upgrade

sudo apt install -y \
    build-essential \
    curl \
    exuberant-ctags \
    gdb \
    git \
    htop \
    nasm \
    nodejs \
    python \
    re2c \
    scrot \
    tmux \
    weechat-curses weechat-plugins \
    zsh

# Vim
# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
sudo apt remove vim vim-runtime gvim
sudo apt install -y libncurses5-dev libgnome2-dev libgnomeui-dev \
    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
    ruby-dev

git clone https://github.com/vim/vim.git ~/vim
cd ~/vim
./configure --with-features=huge \
            --enable-multibyte \
            --enable-rubyinterp \
            --enable-pythoninterp \
            --with-python-config-dir=/usr/lib/python2.7/config \
            --enable-perlinterp \
            --enable-luainterp \
            --enable-gui=gtk2 --enable-cscope --prefix=/usr
make VIMRUNTIMEDIR=/usr/share/vim/vim74
sudo make install

sudo update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
sudo update-alternatives --set editor /usr/bin/vim
sudo update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
sudo update-alternatives --set vi /usr/bin/vim
