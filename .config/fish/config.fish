# No greeting.
set fish_greeting

if status --is-interactive
  # Source dotfiles.
  source ~/.aliases
  source ~/.exports

  # Source fish files.
  source ~/.config/fish/gpg.fish
  source ~/.config/fish/fzf.fish
  source ~/.config/fish/ssh.fish

  # Source localrc which is not sync'd.
  source ~/.localrc
end
