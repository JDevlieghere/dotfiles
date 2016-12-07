function browse -d "Browse webpage"
  curl -s "http://fuckyeahmarkdown.com/go/?u=$argv&read=1&submit=go" | fold -w 80 -s |  highlight --syntax md --out-format ansi | less -R
end
