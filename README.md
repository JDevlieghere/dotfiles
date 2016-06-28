# Dotfiles

> This is my dotfile repository. There are many like it, but this one is mine.

I did my best to make everythings work as transparently as possible under both Linux and macOS. 
**Feel free to try out my dotfiles or use them as inspiration!** If you have a suggestion, improvement or question, don't hesitate to open an issue.

## Screenshot

![xmonad solarized dark](http://i.imgur.com/yYW8VRb.png)


## Installation

Use the bootstrap script to synchronize the dotfiles to your home directory.

```
cd ~
git clone https://github.com/JDevlieghere/dotfiles.git
cd dotfiles
./bootstrap.sh
```

### Vim & YouCompleteMe

Vim is my editor of choice. Most of my [.vimrc](https://github.com/JDevlieghere/dotfiles/blob/master/.vimrc) should be self-explanatory. For C++ development, I rely heavily on [YouCompleteMe](https://github.com/Valloric/YouCompleteMe) for which I created [a better .ycm_extra_conf.py](https://jonasdevlieghere.com/a-better-youcompleteme-config/). 

## macOS

The `.macos` file contains some sensible defaults for OSX, heavily inspired by
[Mathias Bynens'
dotfiles](https://github.com/mathiasbynens/dotfiles/blob/master/.osx). These
are automatically set on running the bootstrap script under macOS.

## xmonad

When I got started with xmonad I came across [Vic Fryzel's
configuration](https://github.com/vicfryzel/xmonad-config) which I grew fond of
over time. It is still largely the same, except for the solarized dark theming
and a few functional improvements here and there.

On Ubuntu you will need the following additional packages:

```
compton dmenu feh hsetroot scrot xmobar xmonad
```
