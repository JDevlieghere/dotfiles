function vdiff -d "Vim diff the same file between directories"
  set --local lhs (realpath $argv[2])
  set --local rhs (realpath $argv[1]/$argv[2])
  echo "Diffing '$lhs' with '$rhs'"
  vimdiff $lhs $rhs
end

