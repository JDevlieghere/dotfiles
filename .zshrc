# Path to oh-my-zsh installation
export ZSH=$HOME/.oh-my-zsh

# Theme
ZSH_THEME="mh"

# How often to auto-update (in days)
export UPDATE_ZSH_DAYS=7

# Enable command auto-correction
ENABLE_CORRECTION="true"

# Command execution time stamp shown in the history command output
HIST_STAMPS="yyyy-mm-dd"

# Plugins to load

# User configuration
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/usr/texbin:$HOME/bin"

source $ZSH/oh-my-zsh.sh

# Language environment
export LANG=en_US.UTF-8

# SSH
export SSH_KEY_PATH="~/.ssh/id_rsa"

# Personal aliases
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

# Source dotfiles
source ~/.aliases
source ~/.exports
source ~/.functions

# Start SSH Agent
if [ -z "$SSH_AUTH_SOCK" ] ;
then
  eval `ssh-agent -s`
  ssh-add
fi

# Configuration not part of the repository
if [[ -a ~/.localrc ]]
then
      source ~/.localrc
fi

# Source fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# No duplicates in history
setopt HIST_IGNORE_ALL_DUPS
