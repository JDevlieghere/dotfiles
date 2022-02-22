#!/usr/bin/env bash

DOTFILES=$(pwd -P)

info() {
    printf "\033[00;34m$@\033[0m\n"
}

doUpdate() {
    info "Updating"
    git pull origin main
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
        git config --global mergetool.araxis.path /Applications/Araxis\ Merge.app/Contents/Utilities/compare
    fi

    # Use Sublime Merge as diff and merge tool when available.
    if [ -d "/Applications/Sublime Merge.app/Contents/SharedSupport/bin/" ]; then
        echo "Configuring Sublime Merge"
        git config --global mergetool.smerge.cmd 'smerge mergetool "$BASE" "$LOCAL" "$REMOTE" -o "$MERGED"'
        git config --global mergetool.smerge.trustExitCode true
        git config --global merge.tool smerge
    fi

    diff_so_fancy=$(type -P "diff-so-fancy")
    if [ -x "$diff_so_fancy" ]; then
        echo "Configuring diff-so-fancy"
        git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
        git config --global interactive.diffFilter "diff-so-fancy --patch"
        git config --global --bool diff-so-fancy.markEmptyLines false
        git config --global color.diff-highlight.oldNormal    "red bold"
        git config --global color.diff-highlight.oldHighlight "red bold 52"
        git config --global color.diff-highlight.newNormal    "green bold"
        git config --global color.diff-highlight.newHighlight "green bold 22"
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
        --exclude "sublime/" \
        --exclude "tmux.terminfo" \
        --filter=':- .gitignore' \
        -avh --no-perms . ~;

    # Touch .localrc so fish can source it.
    touch ~/.localrc

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

doDirectories() {
    mkdir -p ~/.vim/undo
    mkdir -p ~/.ssh
    mkdir -p ~/.gnupg
}

doInstall() {
    info "Installing Extras"

    # vim
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +PlugUpdate +qa!

    if command -v nvim &> /dev/null; then
        nvim +PlugInstall +PlugUpdate +qa!
    fi

    # tmux
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

    # fzf
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all

    # rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh
    chmod +x /tmp/rustup-init.sh
    /tmp/rustup-init.sh -y
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

doPermissions() {
    info "Fixing Permissions "

    chown -R $(whoami) $HOME/.ssh/
    find $HOME/.ssh -type d -exec chmod 700 {} \;
    find $HOME/.ssh -type f -name 'id_rsa*' -exec chmod 600 {} \;
    find $HOME/.ssh -type f -name '*.pub' -exec chmod 644 {} \;

    chown -R $(whoami) $HOME/.gnupg/
    find $HOME/.gnupg -type f -exec chmod 600 {} \;
    find $HOME/.gnupg -type d -exec chmod 700 {} \;
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
    doDirectories
    doPermissions
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
                doDirectories
                doPermissions
                shift
                ;;
            -l|--link)
                doSymLink
                shift
                ;;
            -i|--install)
                doInstall
                doFonts
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
