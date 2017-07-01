function chld -d "Change linker"
  set --local dest /usr/local/bin/ld
  set --local source /usr/bin/$argv[1]
  if test -e $source
    if test -s $dest
      sudo unlink $dest
    end
    echo "Creating symlink to make $argv[1] default linker."
    sudo ln -s $source $dest
    ld --version
  end
end
