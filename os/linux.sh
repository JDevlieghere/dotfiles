#!/usr/bin/env bash

# Use gold
sudo unlink /usr/bin/ld && sudo ln -s /usr/bin/ld.gold /usr/bin/ld

if [ "$GDMSESSION" == "gnome" ];  then
  echo "Configuring GNOME"
  gsettings set org.gnome.desktop.peripherals.keyboard delay 250
  gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 15
fi

