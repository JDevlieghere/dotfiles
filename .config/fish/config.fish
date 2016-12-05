# No greeting.
set --erase fish_greeting

# Source dotfiles.
source ~/.aliases
source ~/.exports

# Source fish files.
source ~/.config/fish/gpg.fish
source ~/.config/fish/fzf.fish

# Source localrc which is not sync'd.
source ~/.localrc
