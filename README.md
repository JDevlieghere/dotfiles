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


## My Setup

 - **Terminal Emulator**: [Ghostty](https://ghostty.org) & [Alacratty](https://alacritty.org)
    - Theme: [Solarized Dark](https://ethanschoonover.com/solarized/)
    - Font: [MonoLisa](https://www.monolisa.dev)
    - Configuration: [ghostty/config](https://github.com/JDevlieghere/dotfiles/blob/main/.config/ghostty/config) and [alacritty.toml](https://github.com/JDevlieghere/dotfiles/blob/main/.config/alacritty/alacritty.toml)
 - **Shell**: [Fish Shell](https://fishshell.com)
    - Prompt: [Starship](https://starship.rs)
    - Configuration: [.config/fish](https://github.com/JDevlieghere/dotfiles/tree/main/.config/fish) and [starship.toml](https://github.com/JDevlieghere/dotfiles/blob/main/.config/starship.toml)
 - **Editor**: [Neovim](https://neovim.io)
    - Plugin Manager: [Lazy.nvim](https://lazy.folke.io)
    - Configuration: [.vimrc](https://github.com/JDevlieghere/dotfiles/blob/main/.vimrc) and [.config/nvim](https://github.com/JDevlieghere/dotfiles/tree/main/.config/nvim)

## Useful Stuff

 - [Scripts](https://github.com/JDevlieghere/dotfiles/tree/main/scripts)
 - [OS Configurations](https://github.com/JDevlieghere/dotfiles/tree/main/os)

## Acknowledgments

 - The `os/macos.sh` script with sensible macOS defaults is forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles/blob/main/.macos).
