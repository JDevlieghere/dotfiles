#!/usr/bin/env bash

if [ "$GDMSESSION" == "gnome" ];  then
  echo "Configuring GNOME"
  gsettings set org.gnome.desktop.peripherals.keyboard delay 250
  gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 15
fi
