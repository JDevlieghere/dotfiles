#in event handler: handler for generic event 'fish_job_summary'!/usr/bin/env bash

# shellcheck disable=SC2016

DOTFILES=$(dirname "$0")

info() {
    printf "\033[00;34m%s\033[0m\n" "$@"
}

doUpdate() {
    info "Updating"
    git pull origin main
}

doGitConfig() {
    info "Configuring Git"

    # The .gitconfig will be overwritten; reconfigure it.
    echo "Configuring global .gitignore"
    git config --global core.excludesfile "$HOME/.gitignore_global"

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

        git config --global mergetool.smerge.cmd '/Applications/Sublime\ Merge.app/Contents/SharedSupport/bin/smerge mergetool "$BASE" "$LOCAL" "$REMOTE" -o "$MERGED"'
        git config --global mergetool.smerge.trustExitCode true
        git config --global merge.guitool smerge
    fi

    delta=$(type -P "delta")
    if [ -x "$delta" ]; then
        echo "Configuring delta"

        git config --global core.pager "delta"
        git config --global interactive.diffFilter "delta --color-only"
    fi
}

doToolConfig() {
    info "Configuring Tools"

    fish=$(type -P "fish")
    if [ -x "$fish" ]; then
        echo "Configuring fish theme"
        "$fish" "$DOTFILES/.config/fish/solarized.fish"
    fi
}

doSync() {
    info "Syncing"
    rsync \
        --exclude ".git/" \
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
        --no-perms \
        -avh \
        "$DOTFILES/" \
        "$HOME"

    # Touch .localrc so fish can source it.
    touch "$HOME/.localrc"

    # Copy Sublime configurations.
    if [ -d "$HOME/Library/Application Support/Sublime Merge/" ]; then
        cp -f "$DOTFILES/sublime/merge/Preferences.sublime-settings" \
              "$HOME/Library/Application Support/Sublime Merge/Packages/User/Preferences.sublime-settings"
    fi

    if [ -d "$HOME/Library/Application Support/Sublime Text/" ]; then
        cp -f "$DOTFILES/sublime/text/Preferences.sublime-settings" \
              "$HOME/Library/Application Support/Sublime Text/Packages/User/Preferences.sublime-settings"
    fi
}

doDirectories() {
    mkdir -p "$HOME/vim/undo"
    mkdir -p "$HOME/.ssh"
    mkdir -p "$HOME/.gnupg"
}

doInstall() {
    if command -v nvim &> /dev/null; then
        info "Installing neovim plugins"
        nvim --headless "+Lazy! sync" +qa
        if command -v pip3 &> /dev/null; then
            pip3 install neovim
        fi
    fi

    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        info "Installing tmux plugins"
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    else
        info "Updating tmux plugins"
        "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
    fi

    if command -v rustup &> /dev/null; then
        info "Updating Rust"
        rustup update
    else
        info "Installing Rust"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh
        chmod +x /tmp/rustup-init.sh
        /tmp/rustup-init.sh -y
    fi

    if command -v brew &> /dev/null; then
        info "Updating Homebrew"
        brew update
        brew upgrade
    fi
}

doPermissions() {
    info "Fixing Permissions "

    chown -R "$(whoami)" "$HOME/.ssh/"
    find "$HOME/.ssh" -type d -exec chmod 700 {} \;
    find "$HOME/.ssh" -type f -name 'id_rsa*' -exec chmod 600 {} \;
    find "$HOME/.ssh" -type f -name '*.pub' -exec chmod 644 {} \;

    chown -R "$(whoami)" "$HOME/.gnupg/"
    find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
    find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
}

doOSConfig() {
    info "Configuring OS"

    if [ "$(uname)" == "Darwin" ]; then
        echo "Configuring macOS"
        "$DOTFILES/os/macos.sh"
    elif [ "$(uname)" == "Linux" ]; then
        echo "Configuring Linux"
        "$DOTFILES/os/linux.sh"
    fi
}

doAll() {
    doUpdate
    doSync
    doGitConfig
    doDirectories
    doPermissions
    doInstall
    doOSConfig
}

doHelp() {
    echo "Usage: $(basename "$0") [options]" >&2
    echo
    echo "   -s, --sync             Synchronizes dotfiles to home directory"
    echo "   -l, --link             Create symbolic links"
    echo "   -i, --install          Install (extra) software"
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
                doToolConfig
                doDirectories
                doPermissions
                shift
                ;;
            -i|--install)
                doInstall
                shift
                ;;
            -c|--config)
                doOSConfig
                shift
                ;;
            -a|--all)
                doAll
                shift
                ;;
            *)
                doHelp
                ;;
        esac
    done
fi
