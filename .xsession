#!/bin/sh

# Enable access to scripts
PATH=$PATH:~/.cabal/bin:~/bin

# Configure X
xsetroot -cursor_name left_ptr &
if [ -f ~/.Xresources ];
then
    xrdb -merge .Xresources &
fi

# Start sound server
pulseaudio --start &

# Start compton
compton --config ~/.compton.conf &

# Start a terminal instance
gnome-terminal &

# Start a browser instance
google-chrome &

# Start xmonad WM
exec xmonad
