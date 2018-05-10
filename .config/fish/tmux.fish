if status is-interactive
and not set -q TMUX
    tmux attach ;or tmux new
end
