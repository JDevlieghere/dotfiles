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
	fi

	# Disable analytics.
	brew analytics off
}

installEssentials() {
	info "Installing essentials"

	brew install fd
	brew install fish
	brew install fzf
	brew install git
	brew install gnupg
	brew install neovim
	brew install pinentry-mac
	brew install ripgrep
	brew install swig
	brew install tmux
	brew install vim
}

installBasics() {
	info "Installing basics"

	brew install bat
	brew install boost
	brew install clang-format
	brew install cloc
	brew install cmake
	brew install creduce
	brew install ctags
	brew install doxygen
	brew install git-delta
	brew install git-lfs
	brew install github/gh/gh
	brew install graphviz
	brew install highlight
	brew install htop
	brew install hyperfine
	brew install imagemagick
	brew install lcov
	brew install libxml2
	brew install lua@5.3
	brew install ncdu
	brew install neofetch
	brew install ninja
	brew install node
	brew install pandoc
	brew install patchutils
	brew install python
	brew install re2c
	brew install redis
	brew install rsync
	brew install sccache
	brew install the_silver_searcher
	brew install tig
	brew install tree
	brew install vbindiff
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
	brew install ffmpeg
	brew install findutils
	brew install gdb
	brew install gnu-sed
	brew install gnutls
	brew install gts
	brew install libiconv
	brew install mosh
	brew install radare2
	brew install ranger
	brew install shellcheck
	brew install valgrind
	brew install wget --with-iri
	brew install wireshark --with-qt5
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
}


help() {
	echo "Usage: $(basename "$0") [options]" >&2
	echo
	echo "   -i, --install          Install"
	echo "   -e, --extras           Install extras"
	echo "   -u, --update           Update brew and formulae"
	echo "   -l, --list             List installed formulae"
	echo "   -m, --minimal          Install just the essentials"
	echo
	exit 1
}

if [ $# -eq 0 ]; then
	help
else
	for i in "$@"
	do
		case $i in
			-m|--minimal)
				update
				installEssentials
				cleanup
				list
				shift
				;;
			-i|--install)
				update
				installEssentials
				installBasics
				cleanup
				list
				shift
				;;
			-e|--extras)
				update
				installExtras
				cleanup
				list
				shift
				;;
			-f|--fix)
				shift
				;;
			-u|--update)
				update
				cleanup
				shift
				;;
			-l|--list)
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
