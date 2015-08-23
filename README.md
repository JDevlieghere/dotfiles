# Dotfiles

This is my dotfile repository. There are many like it, but this one is mine.

Although I tried to make everything as self-explanatory as possible, sometimes
it's better to have information centralized. That's what this README is for.

 - [Installation](#installation)
 - [Vim](#vim)
 - [Xmonad](#xmonad)

## Screenshots

### Xmonad

![xmonad solarized dark](http://i.imgur.com/yYW8VRb.png)

### Vim

![vim solarized dark](http://i.imgur.com/Hf0jbYL.png)

## Requirements and Dependencies

Except for `git` and `curl` which are used in the installation script, not all packages listed below are required. It is a matter of which part of my configuration you are interested in. 

```
amixer compton curl dmenu exuberant-ctags git scrot tmux vim xmobar xmonad
```

## Installation


Run the command below from the home directory. It will clone the dotfiles repository and run the bootstrap script.

```
git clone https://github.com/JDevlieghere/dotfiles.git ~/dotfiles && cd ~/dotfiles  &&  sourc ./bootstrap.sh
```

## Vim

Vim is my editor of choice and I've tweaked my configuration quite a bit to
make it fit my particular needs. Today it's used mainly for C++ development. I
use [Vundle](https://github.com/VundleVim/Vundle.vim) to manage my plugins. You
can have a look at the respective repositories to discover what each of them
does.

### YouCompleteMe

One plugin worth mentioning is
[YouCompleteMe](https://github.com/Valloric/YouCompleteMe) as it requires some
attention to install, so make sure to check its documentation.

For semantic completion it
[requires](https://github.com/Valloric/YouCompleteMe#c-family-semantic-completion-engine-usage)
an addition configuration file `.ycm_extra_conf.py` containing project specific
compilation flags. I use a global file that looks for a [compilation
database](http://clang.llvm.org/docs/JSONCompilationDatabase.html) or
alternatively for an `include` directory and a `.clang_complete` file in the
current working directory or in any directory above it in the hierarchy. It
then reads the compile flags from the respective file.

## Xmonad

When I got started with xmonad I came across [Vic Fryzel's
configuration](https://github.com/vicfryzel/xmonad-config) which I grew fond of
over time. It is still largely the same, except for the solarized dark theming
and a few functional improvements here and there.
