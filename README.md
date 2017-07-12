# Dotfiles

> This is my dotfile repository. There are many like it, but this one is mine.

I did my best to make everythings work as transparently as possible under both
Linux and macOS.

**Feel free to try out my dotfiles or use them as inspiration!** If you have a
suggestion, improvement or question, don't hesitate to open an issue.

## Screenshots

![macOS](https://i.imgur.com/1HKzLs7.png)
![Voltron](https://i.imgur.com/pNVKuy0.png)

## Installation

Use the bootstrap script to synchronize the dotfiles to your home directory.

```
cd ~
git clone https://github.com/JDevlieghere/dotfiles.git
cd dotfiles
./bootstrap.sh -a
```

If you decide to use this configuration as is, don't forget to change your name
and e-mail address in the `.gitconfig` and `.hgrc` files.

## Vim & YouCompleteMe

Vim is my editor of choice. Most of my
[.vimrc](https://github.com/JDevlieghere/dotfiles/blob/master/.vimrc) should be
self-explanatory. For C++ development, I rely heavily on
[YouCompleteMe](https://github.com/Valloric/YouCompleteMe) for which I created
[a better
.ycm_extra_conf.py](https://jonasdevlieghere.com/a-better-youcompleteme-config/).

## OS Specific Configuration

The shell scripts in the `os` folder contains configurations for different
operating systems. These files are automatically executed when running the
bootstrap script under the corresponding operating system.

### macOS

The `os/macos.sh` file contains some sensible defaults for OSX. The file is
heavily inspired by [Mathias Bynens'
dotfiles](https://github.com/mathiasbynens/dotfiles/blob/master/.macos).

### Linux

The `os/linux.sh` file contains some configuration values for Gnome 3.

## tmux

Instead of constantly polling for the current WAN IP, I have my tmux read a
cache file which is updated every five minutes by a cron job.

```
*/5 * * * * dig +short myip.opendns.com @resolver1.opendns.com > ~/.tmux.cache.ip
```

## xmonad

When I got started with xmonad I came across [Vic Fryzel's
configuration](https://github.com/vicfryzel/xmonad-config) which I grew fond of
over time. It is still largely the same, except for the solarized dark theming
and a few functional improvements here and there.

On Ubuntu you will need the following additional packages:

```
compton dmenu feh hsetroot scrot xmobar xmonad
```
