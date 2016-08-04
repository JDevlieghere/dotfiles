# Path to oh-my-zsh installation
export ZSH=$HOME/.oh-my-zsh

# Theme
ZSH_THEME="ys"

# How often to auto-update (in days)
export UPDATE_ZSH_DAYS=7

# Enable command auto-correction
ENABLE_CORRECTION="true"

# Command execution time stamp shown in the history command output
HIST_STAMPS="yyyy-mm-dd"

# No duplicates in history
setopt HIST_IGNORE_ALL_DUPS

# User configuration
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/texbin:$HOME/bin:$PATH"

source $ZSH/oh-my-zsh.sh

# Oh-My-Zsh aliases
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

# Dotfiles
source ~/.shellrc
