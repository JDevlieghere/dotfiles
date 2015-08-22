#!/bin/sh
# Script to display current volume in xmobar

VOLUME=$(amixer get Master | egrep -o "[0-9]+%")
echo "Volume: ${VOLUME}"

