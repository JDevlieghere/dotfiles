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

> [!WARNING]
>
> If you decide to use this configuration as is, don't forget to change your
> name and e-mail address in `.gitconfig`.

## Application Configurations

### neovim

I started out using vim with
[YouCompleteMe](https://github.com/Valloric/YouCompleteMe) before moving over
to neovim for its built-in LSP support. For a long time I kept my configuration
compatible with both vim and neovim. I've given up on that and have now fully
committed to neovim with [lazy.nvim](https://github.com/folke/lazy.nvim) as my
plugin manager.

### fish

I use [fish](https://fishshell.com) as my shell.

```
chsh -s $(which fish)
```

> [!NOTE]
>
> On macOS, you'll have to append `/etc/shells` with the absolute path to
> `fish`.


## Other Useful Stuff

 - [Scripts](https://github.com/JDevlieghere/dotfiles/tree/main/scripts)
 - [System Configurators](https://github.com/JDevlieghere/dotfiles/tree/main/os)

## Acknowledgements

 - The `os/macos.sh` script with sensible macOS defaults is forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles/blob/main/.macos).
 - I use [MonoLisa](https://www.monolisa.dev) as my font.
