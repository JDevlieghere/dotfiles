#!/usr/bin/env bash

pushd `dirname $0` > /dev/null
DOTFILES=`pwd -P`
popd > /dev/null

info () {
    printf "\033[00;34m$@\033[0m\n"
}

doUpdate() {
    info "Updating"
    git pull origin master;
}

doSync() {
    info "Syncing"
    rsync --exclude ".git/" \
        --exclude "installers/" \
        --exclude ".DS_Store"  \
        --exclude "bootstrap.sh" \
        --exclude "README.md" \
        --exclude ".gitignore" \
        --filter=':- .gitignore' \
        -avh --no-perms "$DOTFILES" ~;
}

doLink() {
    mkdir -p ~/.config
    ln -s ~/.vim ~/nvim
    ln -s ~/.vimrc ~/nvim/init.vim
}

doInstall() {
    info "Installing Extras"
    curl -sL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf

    if [ "$(uname)" == "Darwin" ]; then
        source "$DOTFILES/installers/brew.sh"
    fi

    source "$DOTFILES/installers/python.sh"
}

doFonts() {
    info "Installing Fonts"
    if [ "$(uname)" == "Darwin" ]; then
        fonts=~/Library/Fonts
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        fonts=~/.fonts
        mkdir -p "$fonts"
    fi

    find "$DOTFILES/fonts/" -name "*.[o,t]tf" -type f | while read file; do cp -v "$file" "$fonts"; done
}

doConfig() {
    info "Configuring"
    source ~/.zshrc;
    if [ "$(uname)" == "Darwin" ]; then
        source "$DOTFILES/.osx"
    fi
}

doAll() {
    doUpdate
    doSync
    doLink
    doInstall
    doFonts
    doConfig
}

if [ "$1" == "--sync" ]; then
    doSync
    doConfig
elif [ "$1" == "--install" ]; then
    doInstall
elif [ "$1" == "--fonts" ]; then
    doFonts
else
    doAll
fi
