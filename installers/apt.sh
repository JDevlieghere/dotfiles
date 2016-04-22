sudo apt-get update
sudo apt-get upgrade

sudo apt-get install -y build-essential
sudo apt-get install -y cmake
sudo apt-get install -y curl
sudo apt-get install -y exuberant-ctags
sudo apt-get install -y git
sudo apt-get install -y htop
sudo apt-get install -y ncurses
sudo apt-get install -y nodejs
sudo apt-get install -y python
sudo apt-get install -y scrot
sudo apt-get install -y tmux
sudo apt-get install -y weechat-curses weechat-plugins
sudo apt-get install -y zsh

# Vim
# https://github.com/Valloric/YouCompleteMe/wiki/Building-Vim-from-source
sudo apt-get remove vim vim-runtime gvim
sudo apt-get install libncurses5-dev libgnome2-dev libgnomeui-dev \
    libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
    libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
    ruby-dev git
    cd ~
    
git clone https://github.com/vim/vim.git
cd vim
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
