# Dotfiles

> This is my dotfile repository. There are many like it, but this one is mine.

I did my best to make everything work as transparently as possible under both
Linux and macOS.

**Feel free to try out my dotfiles or use them as inspiration!** If you have a
suggestion, improvement or question, don't hesitate to open an issue.

## Screenshot

![macOS](https://jonasdevlieghere.com/static/dotfiles.png)

## Installation

Clone the dotfiles repository.

```
cd ~
git clone https://github.com/JDevlieghere/dotfiles.git
cd dotfiles
```

Use the bootstrap script to do everything from synchronizing the files to
installing additional fonts.

```
Usage: bootstrap.sh [options]

   -s, --sync             Synchronizes dotfiles to home directory
   -i, --install          Install (extra) software
   -f, --fonts            Copies font files
   -c, --config           Configures your system
   -a, --all              Does all of the above
./bootstrap.sh -a
```

If you decide to use this configuration as is, don't forget to change your name
and e-mail address in the `.gitconfig` and `.hgrc` files.

## Application Configurations

### Vim & YouCompleteMe

Vim is my editor of choice. Most of my
[.vimrc](https://github.com/JDevlieghere/dotfiles/blob/master/.vimrc) should be
self-explanatory. For C++ development, I rely heavily on
[YouCompleteMe](https://github.com/Valloric/YouCompleteMe) for which I created
[a better .ycm_extra_conf.py](https://jonasdevlieghere.com/a-better-youcompleteme-config/).


### tmux

My tmux configuration will display your WAN IP address in the bottom right
corner. Instead of constantly polling for the current IP, it reads a cache
file which is updated every five minutes by a cron job.

```
*/5 * * * * curl -s http://whatismyip.akamai.com > ~/.tmux.cache.ip
```

To enable italics you will need to compile and install  `tmux.terminfo`.

```
tic -x tmux.terminfo
```

### git

My git is configured to sign every commit with the machine's GPG key.

### fish

I use [fish shell](https://fishshell.com), a smart and user-friendly command
line shell for macOS, Linux, and the rest of the family.

```
chsh -s $(which fish)
```

Remember that on macOS you'll have the fish's path to `/etc/shells`.

## Other Useful Stuff

 - [Install scripts](https://github.com/JDevlieghere/dotfiles/tree/master/installers)
 - [Fonts](https://github.com/JDevlieghere/dotfiles/tree/master/fonts)
 - [Configuration scripts](https://github.com/JDevlieghere/dotfiles/tree/master/os)

## Acknowledgements

 - My xmonad configuration is based on [Vic Fryzel's configuration](https://github.com/vicfryzel/xmonad-config).
 - The `os/macos.sh` script with sensible macOS defaults is forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles/blob/master/.macos).


