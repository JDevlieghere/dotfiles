function path-append
  if count $argv > /dev/null
    set PATH $PATH $argv
  else
    set PATH $PATH $PWD
  end
end
