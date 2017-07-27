#!/usr/bin/env bash

DOTFILES=$(pwd -P)

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
        --exclude "os/" \
        --exclude "bootstrap.sh" \
        --exclude "README.md" \
        --exclude ".gitignore" \
        --filter=':- .gitignore' \
        -avh --no-perms . ~;

    # The .gitconfig will be overwritten; reconfigure it.
    git config --global core.excludesfile ~/.gitignore_global

    # Copy files that have different locations on macOS and Linux.
    if [ -d "$HOME/Library/Application Support/Code/User/" ]; then
        cp -f "$HOME/.config/Code/User/settings.json" \
            "$HOME/Library/Application Support/Code/User/settings.json"
    fi
}

doInstall() {
    info "Installing Extras"

    # plug.vim
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    # tmux Plugin Manager
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    # FZF
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
}

doFonts() {
    info "Installing Fonts"

    if [ "$(uname)" == "Darwin" ]; then
        fonts=~/Library/Fonts
    elif [ "$(uname)" == "Linux" ]; then
        fonts=~/.fonts
        mkdir -p "$fonts"
    fi

    find "$DOTFILES/fonts/" -name "*.[o,t]tf" -type f | while read -r file
    do
        cp -v "$file" "$fonts"
    done
}

doConfig() {
    info "Configuring"

    if [ "$(uname)" == "Darwin" ]; then
        echo "Configuring macOS"
        ./os/macos.sh
    elif [ "$(uname)" == "Linux" ]; then
        echo "Configuring Linux"
        ./os/linux.sh
    fi
}

doAll() {
    doUpdate
    doSync
    doInstall
    doFonts
    doConfig
}

doHelp() {
    echo "Usage: $(basename "$0") [options]" >&2
    echo
    echo "   -s, --sync             Synchronizes dotfiles to home directory"
    echo "   -i, --install          Install (extra) software"
    echo "   -f, --fonts            Copies font files"
    echo "   -c, --config           Configures your system"
    echo "   -a, --all              Does all of the above"
    echo
    exit 1
}

if [ $# -eq 0 ]; then
    doHelp
else
    for i in "$@"
    do
        case $i in
            -s|--sync)
                doSync
                shift
                ;;
            -i|--install)
                doInstall
                shift
                ;;
            -f|--fonts)
                doFonts
                shift
                ;;
            -c|--config)
                doConfig
                shift
                ;;
            -a|--all)
                doAll
                shift
                ;;
            *)
                doHelp
                shift
                ;;
        esac
    done
fi
