function ssh
  if type -q autossh
    set -f ssh_command "autossh"
    set -f ssh_options "-M 0"
  else
    set -f ssh_command "ssh"
  end

  if test -n $TMUX
    tmux rename-window (echo "$argv" | cut -d '@' -f 2)
    command $ssh_command $ssh_options $argv
    tmux set-window-option automatic-rename "on" 1>/dev/null
  else
    command $ssh_command $ssh_options $argv
  end
end
