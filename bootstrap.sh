#!/bin/bash

DOTFILES="$HOME/dotfiles"
LOG="$HOME/dotfiles.log"

log () {
    printf "$1\n" >> "$LOG"
}

info () {
    printf "\n\r\033[2K  [\033[00;34mINFO\033[0m] $1\n"
}

success () {
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
    printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
}

link(){
    local from="$DOTFILES/$1"
    local to="$HOME/$1"

    log "Linking  $from to $to"

    if [ ! -e $to ] && [ ! -L $to ]
    then
        ln -s "$from" "$to"
        success "Linked: $to -> $from"
    else
        fail  "File already exists: $to"
    fi
}

runCommand() {
    log "$1"
    eval $2 >> $LOG 2>&1
    if [ $? -ne 0 ]; then
        fail "$1"
    else
        success "$1"
    fi
}

copyFont() {
    runCommand "Install font $1" "cp $1 $2"
}

installFonts() {
    if [ "$(uname)" == "Darwin" ]; then
        fonts="$HOME/Library/Fonts"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        fonts="$HOME/.fonts"
        mkdir -p "$fonts"
    fi

    find "$DOTFILES/fonts" -name "*.[o,t]tf" -type f | while read file; do copyFont "$file" "$fonts"; done

}

info "Linking files"
link ".aliases"
link ".exports"
link ".functions"
link ".gitconfig"
link ".vim"
link ".vimrc"
link ".xmonad"
link ".zshrc"
link ".tmux.conf"
link ".compton.conf"
link ".xsession"
link "bin"

info "Installing software"
runCommand "Install Oh My Zsh" "curl -s -L https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sh"
runCommand "Install zsh syntax highlighting" "git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/zsh-syntax-highlighting"
runCommand "Install Vundle" "git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim"

info "Installing fonts"
installFonts

info "See $LOG for a detailed log"
echo -e "\n"
