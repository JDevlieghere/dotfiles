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
$ ./bootstrap.py -h
usage: bootstrap.py [-h] [-s] [-i] [-c] [-a]

Bootstrap script for dotfiles setup and configuration.

optional arguments:
  -h, --help     show this help message and exit
  -s, --sync     Synchronizes dotfiles to home directory
  -i, --install  Install (extra) software
  -c, --config   Configures your system
  -a, --all      Does all of the above
```

> [!WARNING]
>
> If you decide to use this configuration as is, don't forget to change your
> name and e-mail address in `.gitconfig`.

> [!NOTE]
>
> On macOS, you'll have to append the absolute path to `fish` to `/etc/shells`
> before you can change your shell with `chsh -s $(which fish)`.

## My Setup

 - **Terminal Emulator**: [Ghostty](https://ghostty.org) & [Alacritty](https://alacritty.org)
    - Theme: [Solarized Dark](https://ethanschoonover.com/solarized/)
    - Font: [MonoLisa](https://www.monolisa.dev)
    - Configuration: [ghostty/config](https://github.com/JDevlieghere/dotfiles/blob/main/.config/ghostty/config) and [alacritty.toml](https://github.com/JDevlieghere/dotfiles/blob/main/.config/alacritty/alacritty.toml)
 - **Shell**: [Fish Shell](https://fishshell.com)
    - Prompt: [Starship](https://starship.rs)
    - Configuration: [.config/fish](https://github.com/JDevlieghere/dotfiles/tree/main/.config/fish) and [starship.toml](https://github.com/JDevlieghere/dotfiles/blob/main/.config/starship.toml)
 - **Editor**: [Neovim](https://neovim.io)
    - Plugin Manager: [Lazy.nvim](https://lazy.folke.io)
    - Configuration: [.vimrc](https://github.com/JDevlieghere/dotfiles/blob/main/.vimrc) and [.config/nvim](https://github.com/JDevlieghere/dotfiles/tree/main/.config/nvim)
 - **Command Line Tools**
    - [delta](https://github.com/dandavison/delta) A syntax-highlighting pager for git, diff, grep, and blame output.
    - [fd](https://github.com/sharkdp/fd): Simple, fast and user-friendly alternative to find.
    - [fzf](https://github.com/junegunn/fzf): Command-line fuzzy finder.
    - [ripgrep](https://github.com/BurntSushi/ripgrep): Search tool like grep and The Silver Searcher.
    - [tmux](https://github.com/tmux/tmux/wiki): Terminal multiplexer.

## Useful Stuff

 - [Scripts](https://github.com/JDevlieghere/dotfiles/tree/main/scripts)
 - [OS Configurations](https://github.com/JDevlieghere/dotfiles/tree/main/os)

## Acknowledgments

 - The `os/macos.sh` script with sensible macOS defaults is forked from [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles/blob/main/.macos).
