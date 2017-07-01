function path-prepend
  if count $argv > /dev/null
    set PATH $argv $PATH
  else
    set PATH $PWD $PATH
  end
end
