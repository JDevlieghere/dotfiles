function ssh
  if test -n $TMUX
    tmux rename-window (echo "$argv" | cut -d '@' -f 2)
    command ssh $argv
    tmux set-window-option automatic-rename "on" 1>/dev/null
  else
    command ssh $argv
  end
end
