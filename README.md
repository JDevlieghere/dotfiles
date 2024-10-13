# Dotfiles

> This is my dotfile repository. There are many like it, but this one is mine.

My primary operating system is macOS, but I do use Linux occasionally. I always
aim to make everything work for both platforms but no guarantees.

**Feel free to try out my dotfiles or use them as inspiration!** If you have a
suggestion, improvement or question, please open an issue or PR!

## Screenshot

![macOS](https://jonasdevlieghere.com/static/dotfiles.png?v=2)

## Installation

Clone the dotfiles repository.

```
$ git clone https://github.com/JDevlieghere/dotfiles.git ~/dotfiles
$ cd ~/dotfiles
```

Use the bootstrap script to create symbolic links and configure the tools and
operating system.

```
$ ./bootstrap.sh
Usage: bootstrap.sh [options]

   -s, --sync             Synchronizes dotfiles to home directory
   -l, --link             Create symbolic links
   -i, --install          Install (extra) software
   -c, --config           Configures your system
   -a, --all              Does all of the above

$ ./bootstrap.sh -a
```

If you decide to use this configuration as is, don't forget to change your name
and e-mail address in the `.gitconfig` and `.hgrc` files.

## Application Configurations

### (n)vim

After having used [YouCompleteMe](https://github.com/Valloric/YouCompleteMe)
for a long time I switched to LSP and [clangd](https://clangd.llvm.org). I
wrote a [blog post](https://jonasdevlieghere.com/vim-lsp-clangd/) on how to set
it up. More recently I've been using the built-in LSP client in neovim.

### fish

I use [fish shell](https://fishshell.com). On macOS you'll have to add fish's
path to `/etc/shells`.

```
chsh -s $(which fish)
```

## Other Useful Stuff

 - [Scripts](https://github.com/JDevlieghere/dotfiles/tree/main/scripts)
 - [System Configurators](https://github.com/JDevlieghere/dotfiles/tree/main/os)

## Acknowledgements

 - The `os/macos.sh` script with sensible macOS defaults is forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles/blob/main/.macos).
 - I use [MonoLisa](https://www.monolisa.dev) as my font.
