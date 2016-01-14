#!/bin/bash

pushd `dirname $0` > /dev/null
DOTFILES=`pwd -P`
popd > /dev/null

info () {
    printf "\033[00;34m$@\033[0m\n"
}

installFonts() {
    if [ "$(uname)" == "Darwin" ]; then
        fonts="$HOME/Library/Fonts"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        fonts="$HOME/.fonts"
        mkdir -p "$fonts"
    fi

    find "$DOTFILES/fonts/" -name "*.[o,t]tf" -type f | while read file; do cp -v "$file" "$fonts"; done

}

symlink(){
    if [ ! -e $2 ] && [ ! -L $2 ]
    then
        ln -vs "$1" "$2"
    else
        echo "Skipping $1"
    fi
}

info "Installing Fonts"
installFonts

info "Installing Software"
curl -s -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME"/.oh-my-zsh/zsh-syntax-highlighting
git clone https://github.com/gmarik/Vundle.vim.git "$HOME"/.vim/bundle/Vundle.vim

info "Linking Dotfiles"
symlink "$DOTFILES"/.aliases "$HOME"/.aliases
symlink "$DOTFILES"/.compton.conf "$HOME"/.compton.conf
symlink "$DOTFILES"/.exports "$HOME"/.exports
symlink "$DOTFILES"/.functions "$HOME"/.functions
symlink "$DOTFILES"/.gitconfig "$HOME"/.gitconfig
symlink "$DOTFILES"/.tmux.conf "$HOME"/.tmux.conf
symlink "$DOTFILES"/.vim "$HOME"/.vim
symlink "$DOTFILES"/.vimrc "$HOME"/.vimrc
symlink "$DOTFILES"/.xsession "$HOME"/.xsession
symlink "$DOTFILES"/.zshrc "$HOME"/.zshrc
symlink "$DOTFILES"/.gdbinit "$HOME"/.gdbinit

info "Linking Directories"
symlink "$DOTFILES"/.irssi "$HOME"/.irssi
symlink "$DOTFILES"/.xmonad "$HOME"/.xmonad
symlink "$DOTFILES"/bin "$HOME"/bin
