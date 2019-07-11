function checkout-all -d "Recursively checkout git repos"
  set -lx cwd (pwd)
  for i in (find . -name ".git")
    cd (dirname "$i")
    git fetch --tags
    git checkout "$argv"
    cd "$cwd"
  end
end
