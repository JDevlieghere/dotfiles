#!/usr/bin/env bash

DOTFILES=$(pwd -P)

info() {
    printf "\033[00;34m$@\033[0m\n"
}

doUpdate() {
    info "Updating"
    git pull origin master;
}

doGitConfig() {
    info "Configuring Git"

    # The .gitconfig will be overwritten; reconfigure it.
    echo "Configuring global .gitignore"
    git config --global core.excludesfile ~/.gitignore_global

    # Use Araxis Merge as diff and merge tool when available.
    if [ -d "/Applications/Araxis Merge.app/Contents/Utilities/" ]; then
        echo "Configuring Araxis Merge"
        git config --global diff.guitool araxis
        git config --global merge.guitool araxis
    fi
}

doSync() {
    info "Syncing"
    rsync --exclude ".git/" \
        --exclude ".gitignore" \
        --exclude "Preferences.sublime-settings" \
        --exclude "README.md" \
        --exclude "bootstrap.sh" \
        --exclude "installers/" \
        --exclude "os/" \
        --exclude "scripts/" \
        --exclude "tmux.terminfo" \
        --filter=':- .gitignore' \
        -avh --no-perms . ~;

    # Copy files that have different locations on macOS and Linux.
    if [ -d "$HOME/Library/Application Support/Code/User/" ]; then
        cp -f "$HOME/.config/Code/User/settings.json" \
            "$HOME/Library/Application Support/Code/User/settings.json"
    fi
}

doSymLink() {
    mkdir -p ${XDG_CONFIG_HOME:=$HOME/.config}
    ln -s ~/.vim/* $XDG_CONFIG_HOME/nvim
    ln -s ~/.vimrc $XDG_CONFIG_HOME/nvim/init.vim
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
    doGitConfig
    doSymLink
    doInstall
    doFonts
    doConfig
}

doHelp() {
    echo "Usage: $(basename "$0") [options]" >&2
    echo
    echo "   -s, --sync             Synchronizes dotfiles to home directory"
    echo "   -l, --link             Create symbolic links"
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
                doGitConfig
                shift
                ;;
            -l|--link)
                doSymLink
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
