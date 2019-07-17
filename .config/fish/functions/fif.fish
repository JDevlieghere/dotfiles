function fif -d "Find in file"
  rg --files-with-matches --no-messages $argv[1] | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 $argv[1] || rg --ignore-case --pretty --context 10 $argv[1] {}"
end
