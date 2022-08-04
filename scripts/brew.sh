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

  brew install \
    fd \
    fish \
    fzf \
    git \
    gnupg \
    neovim \
    pinentry-mac \
    ripgrep \
    swig \
    tmux \
    vim
}

installBasics() {
  info "Installing basics"

  brew install \
    bat \
    boost \
    clang-format \
    cloc \
    cmake \
    creduce \
    ctags \
    doxygen \
    git-delta \
    git-lfs \
    github/gh/gh \
    graphviz \
    highlight \
    htop \
    hyperfine \
    imagemagick \
    lcov \
    libxml2 \
    lua@5.3 \
    ncdu \
    neofetch \
    ninja \
    node \
    pandoc \
    patchutils \
    python \
    re2c \
    redis \
    rsync \
    sccache \
    the_silver_searcher \
    tig \
    tree \
    vbindiff \
    xz \
    zsh
}

installExtras() {
  info "Installing extras"

  brew install \
    afl-fuzz \
    archey \
    binutils \
    coreutils \
    cppcheck \
    distcc \
    ffmpeg \
    findutils \
    gdb \
    gnu-sed \
    gnutls \
    gts \
    libiconv \
    mosh \
    radare2 \
    ranger \
    shellcheck \
    valgrind \
    wget --with-iri \
    wireshark --with-qt5
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
