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

# Plugins
plugins=(git brew osx tmux)

# Oh-My-Zsh
source $ZSH/oh-my-zsh.sh
alias zshconfig="vim ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"

# Linux specifics
if [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Set the typematic delay and rate for an active X server
    xset r rate 200 50
fi

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

# Source fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Configuration not part of the repository
if [[ -a ~/.localrc ]]
then
      source ~/.localrc
fi
