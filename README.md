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
$ cd ~
$ git clone https://github.com/JDevlieghere/dotfiles.git
$ cd dotfiles
```

Use the bootstrap script to do everything from synchronizing the files to
installing additional fonts.

```
$ ./bootstrap.sh
Usage: bootstrap.sh [options]

   -s, --sync             Synchronizes dotfiles to home directory
   -i, --install          Install (extra) software
   -f, --fonts            Copies font files
   -c, --config           Configures your system
   -a, --all              Does all of the above

$ ./bootstrap.sh -a
```

If you decide to use this configuration as is, don't forget to change your name
and e-mail address in the `.gitconfig` and `.hgrc` files.

## Application Configurations

### vim

After having used [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)
for a long time I switched to LSP and [clangd](https://clangd.llvm.org). I
wrote a [blog post](https://jonasdevlieghere.com/vim-lsp-clangd/) on how to set
it up.


### tmux

To enable italics you will need to compile and install  `tmux.terminfo`.

```
tic -x tmux.terminfo
```

### fish

I use [fish shell](https://fishshell.com). On macOS you'll have to add fish's
path to `/etc/shells`.

```
chsh -s $(which fish)
```

## Other Useful Stuff

 - [Scripts](https://github.com/JDevlieghere/dotfiles/tree/master/scripts)
 - [Fonts](https://github.com/JDevlieghere/dotfiles/tree/master/fonts)
 - [System Configurators](https://github.com/JDevlieghere/dotfiles/tree/master/os)

## Acknowledgements

 - My xmonad configuration is based on [Vic Fryzel's configuration](https://github.com/vicfryzel/xmonad-config).
 - The `os/macos.sh` script with sensible macOS defaults is forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles/blob/master/.macos).


