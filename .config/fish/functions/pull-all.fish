function pull-all -d "Recursively pull git repos"
  set -lx cwd (pwd)
  for i in (find . -type d -name ".git")
    cd (dirname "$i")
    git pull --rebase
    cd "$cwd"
  end
end
