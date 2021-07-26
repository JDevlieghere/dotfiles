# No greeting.
set fish_greeting
set fish_emoji_width 2

if status --is-interactive
  # Source .shellenv first.
  if test -f ~/.shellenv
    source ~/.shellenv
  end

  # Source dotfiles.
  source ~/.aliases
  source ~/.exports

  # Source fish files.
  source ~/.config/fish/brew.fish
  source ~/.config/fish/gpg.fish
  source ~/.config/fish/fzf.fish
  source ~/.config/fish/ssh.fish

  # Source .localrc last which is not sync'd.
  if test -f ~/.shellenv
    source ~/.localrc
  end
end
