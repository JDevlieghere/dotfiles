function fgf -d "Fuzzy find git commit"
  git log --oneline --grep "$argv[1]" | fzf --ansi --preview="git --no-pager show --color=always --stat '{1}' | rg --colors 'match:bg:yellow' --ignore-case --color=always --context 9999 '$argv[1]'" | read -l result; and git show --stat "$result"
end
