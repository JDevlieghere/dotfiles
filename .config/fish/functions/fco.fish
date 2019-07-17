function fco -d "Fuzzy-find and checkout a branch"
  git branch --color=always --all --format "%(refname:short)" | fzf --ansi --preview="git --no-pager log -20 --color=always --stat '{1}' | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 $argv[1]" | read -l result; and git checkout "$result"
end
