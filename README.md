# Dotfiles

This is my dotfile repository. There are many like it, but this one is mine.

Although I tried to make everything as self-explanatory as possible, sometimes
it's better to have information centralized. That's what this README is for.

 - [Installation](#installation)
 - [Vim](#vim)
 - [OSX](#osx)
 - [Xmonad](#xmonad)

## Screenshots

![xmonad solarized dark](http://i.imgur.com/yYW8VRb.png)

![vim solarized dark](http://i.imgur.com/Hf0jbYL.png)

## Installation

Installation consists of cloning the repo and running the bootstrap script. It
assumes you have `git` and `curl` installed on your system.

```
cd ~
git clone https://github.com/JDevlieghere/dotfiles.git
cd dotfiles
./bootstrap.sh
```

By default it will r-sync the dotfiles in this repository to your home folder,
copy the fonts to the appropriate directory and install [Oh My
Zsh](https://github.com/robbyrussell/oh-my-zsh),
[vim-plug](https://github.com/junegunn/vim-plug) and
[fzf](https://github.com/junegunn/fzf). Additional software can be installed
using the script inside the `installers` directory, but need to be executed
manually. 

Alternatively, you can specify the script to only sync (`--sync`), install
(`--install`) or copy the fonts (`--fonts`). The first option is particularly
useful after an update.

## Vim

Vim is my editor of choice and I've tweaked my configuration quite a bit to
make it fit my particular needs. Today it's used mainly for C++ development. I
moved from [Vundle](https://github.com/VundleVim/Vundle.vim) to
[vim-plug](https://github.com/junegunn/vim-plug) to manage my plugins. You can
have a look at their respective repositories to discover what each of them
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

## OSX

The `.osx` file contains some sensible defaults for OSX, heavily inspired by
[Mathias Bynens'
dotfiles](https://github.com/mathiasbynens/dotfiles/blob/master/.osx). These
are automatically set on running the bootstrap script.

### Codesigning GDB

Because the Darwin Kernel requires the debugger to have special permissions
before it is allowed to control other processes, you need to codesign the GNU
Project debugger.

 - Open “Keychain Access” 
 - Open menu Keychain Access > Certificate Assistant > Create a Certificate...
 - Choose “gdb-cert” as name, set “Identity Type” to “Self Signed Root”, set “Certificate Type” to “Code Signing” and select the “Let me override defaults”. 
 - Extend the predefined 365 days period to 3650 days.
 - Click  “Continue” until you get to the “Specify a Location For The Certificate” screen, then set “Keychain to System”.
 - In KeyChain Acces, select “System” and use the context menu to select “Get Info”. Open the “Trust” item, and set “Code Signing” to “Always Trust”.
 - Quit “Keychain Access” and restart the “taskgated” service by killing the process.

Finally sign the binary with the following command:
```
codesign -f -s  "gdb-cert" $(which gdb)
```

## Xmonad

When I got started with xmonad I came across [Vic Fryzel's
configuration](https://github.com/vicfryzel/xmonad-config) which I grew fond of
over time. It is still largely the same, except for the solarized dark theming
and a few functional improvements here and there.

On Ubuntu you will need the following additional packages:
```
compton dmenu feh hsetroot scrot xmobar xmonad
```

