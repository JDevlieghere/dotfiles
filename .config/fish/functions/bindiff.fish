function bindiff -d "Diff binary files"
  set --local tmp1 (mktemp /tmp/XXXXXX)
  set --local tmp2 (mktemp /tmp/XXXXXX)

  xxd -c 1 $argv[1] | cut -d ' ' -f 2 > $tmp1
  xxd -c 1 $argv[1] | cut -d ' ' -f 2 > $tmp2
  vimdiff $tmp1 $tmp2
end

