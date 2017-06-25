#!/usr/bin/env bash

# Install Homebrew or make sure it's up to date
which -s brew
if [[ $? != 0 ]] ; then
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
	brew update
	brew upgrade
fi

# Install formulae
brew install afl-fuzz
brew install ag
brew install binutils
brew install boost
brew install ccache
brew install cloc
brew install cmake
brew install coreutils --with-default-names
brew install cppcheck
brew install ctags
brew install doxygen
brew install dtrx
brew install ffmpeg
brew install findutils --with-default-names
brew install fish
brew install gcc --without-multilib
brew install gdb
brew install git
brew install git-lfs
brew install gnu-sed --with-default-names
brew install gnupg
brew install gnutls
brew install go
brew install gpg-agent
brew install graphviz --with-gts
brew install gts
brew install highlight
brew install htop
brew install lcov
brew install libiconv
brew install libxml2
brew install lua
brew install macvim --with-override-system-vim
brew install ncdu
brew install neofetch
brew install ninja
brew install node
brew install python
brew install radare2
brew install ranger
brew install reattach-to-user-namespace
brew install rust
brew install tig
brew install tmux
brew install tree
brew install unrar
brew install valgrind
brew install weechat --with-perl --with-python
brew install wget --with-iri
brew install wireshark --with-qt5
brew install xz
brew install zsh

# Install casks
brew cask install google-chrome
brew cask install iterm2
brew cask install tunnelblick
brew cask install vlc

# Cleanup
brew cleanup

# Link applications
brew linkapps
