#!/bin/sh

# Enable access to scripts
PATH=$PATH:~/.cabal/bin:~/bin

# Start a terminal instance
gnome-terminal &

# Start a browser instance
google-chrome &

# Start sound server
pulseaudio --start &

# Start compton
compton --config ~/.compton.conf &

# Start xmonad WM
xmonad

