#!/bin/sh
# Usage: shoot.sh deck.html outdir N...
# Chrome does not resolve either path against the working directory.
deck=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
mkdir -p "$2"
out=$(cd "$2" && pwd)
shift 2
for n in "$@"; do
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --disable-gpu \
    --hide-scrollbars --window-size=1600,900 --screenshot="$out/$n.png" "file://$deck#$n" >/dev/null 2>&1
  [ -s "$out/$n.png" ] || { echo "shoot.sh: no screenshot for slide $n" >&2; exit 1; }
done
