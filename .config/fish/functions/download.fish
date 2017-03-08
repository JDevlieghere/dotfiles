function download -d "Download multiple files with curl"
  while read -l line
        echo "$line"
        curl -O "$line"
    end
end
