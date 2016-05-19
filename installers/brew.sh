# Install Homebrew or make sure it's up to date
which -s brew
if [[ $? != 0 ]] ; then
	ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    brew update
	brew upgrade --all
fi

# Install formulae
brew install binutils
brew install cloc
brew install cmake
brew install coreutils
brew install doxygent
brew install findutils
brew install gcc --without-multilib
brew install gdb
brew install git
brew install go
brew install graphviz
brew install htop
brew install lua
brew install macvim --with-override-system-vim
brew install neovim/neovim/neovim
brew install ninja
brew install node
brew install python
brew install rust
brew install tmux
brew install valgrind
brew install weechat --with-perl --with-python
brew install wget --with-iri
brew install xz
brew install zsh

# Cleanup
brew cleanup
