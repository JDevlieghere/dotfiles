#!/usr/bin/env bash

info() {
	printf "\033[00;34m$@\033[0m\n"
}

update() {
	# Install Homebrew or make sure it's up to date.
	which -s brew
	if [[ $? != 0 ]] ; then
		info "Installing"
		ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
	else
		info "Updating"
		brew update
		brew upgrade
		brew cask upgrade
	fi

	# Disable analytics.
	brew analytics off
}

fixOwnershipAndPermissions() {
	DIRS="/usr/local/Frameworks \
		/usr/local/bin \
		/usr/local/etc \
		/usr/local/lib \
		/usr/local/sbin \
		/usr/local/share \
		/usr/local/share/doc \
		/usr/local/share/locale \
		/usr/local/share/man \
		/usr/local/share/man/man1 \
		/usr/local/share/man/man2 \
		/usr/local/share/man/man3 \
		/usr/local/share/man/man4 \
		/usr/local/share/man/man5 \
		/usr/local/share/man/man7 \
		/usr/local/share/man/man8"

	sudo chown -R $(whoami) $DIRS
	chmod u+w $DIRS
}

installEssentials() {
	info "Installing essentials"

	brew install ag
	brew install bat
	brew install boost
	brew install cloc
	brew install cmake
	brew install creduce
	brew install ctags
	brew install doxygen
	brew install dtrx
	brew install fd
	brew install ffmpeg
	brew install fish
	brew install git
	brew install git-lfs
	brew install github/gh/gh
	brew install gnupg
	brew install gpg-agent
	brew install graphviz
	brew install gts
	brew install highlight
	brew install htop
	brew install hyperfine
	brew install imagemagick
	brew install lcov
	brew install libxml2
	brew install lua
	brew install ncdu
	brew install neofetch
	brew install neovim
	brew install ninja
	brew install node
	brew install pandoc
	brew install patchutils
	brew install python
	brew install re2c
	brew install redis
	brew install ripgrep
	brew install rsync
	brew install sccache
	brew install the_silver_searcher
	brew install tig
	brew install tmux
	brew install tree
	brew install unrar
	brew install valgrind
	brew install vbindiff
	brew install vim
	brew install xz
	brew install zsh
}

installExtras() {
	info "Installing extras"

	brew install afl-fuzz
	brew install archey
	brew install binutils
	brew install coreutils
	brew install cppcheck
	brew install distcc
	brew install findutils
	brew install gdb
	brew install gnu-sed
	brew install gnutls
	brew install libiconv
	brew install mosh
	brew install neovim
	brew install radare2
	brew install ranger
	brew install shellcheck
	brew install wget --with-iri
	brew install wireshark --with-qt5
}

installCasks() {
	info "Installing casks"

	brew cask install alacritty
	brew cask install iina
	brew cask install tunnelblick
	brew cask install vlc
}

linkApps() {
	info "Linking apps"

	brew linkapps
}

cleanup() {
	info "Cleanup"

	brew cleanup
}

list() {
	info "List"

	brew list
	brew cask list
}


help() {
	echo "Usage: $(basename "$0") [options]" >&2
	echo
	echo "   -i, --install          Install essentials"
	echo "   -e, --extras           Install extras"
	echo "   -u, --update           Update brew and formulae"
	echo "   -l, --list             List installed formulae"
	echo "   -c, --cask             Install casks"
	echo
	exit 1
}

if [ $# -eq 0 ]; then
	help
else
	for i in "$@"
	do
		case $i in
			-i|--install)
				fixOwnershipAndPermissions
				update
				installEssentials
				cleanup
				list
				shift
				;;
			-e|--extras)
				fixOwnershipAndPermissions
				update
				installExtras
				cleanup
				list
				shift
				;;
			-f|--fix)
				fixOwnershipAndPermissions
				shift
				;;
			-u|--update)
				fixOwnershipAndPermissions
				update
				cleanup
				shift
				;;
			-l|--list)
				list
				shift
				;;
			-c|--cask)
				fixOwnershipAndPermissions
				installCasks
				linkApps
				cleanup
				list
				shift
				;;
			*)
				help
				shift
				;;
		esac
	done
fi
