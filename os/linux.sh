#!/usr/bin/env bash

# Generate locale
sudo locale-gen "en_US.UTF-8"
sudo dpkg-reconfigure locales

# Use LLD if available.
lld=$(which lld)
if [ -x "$lld" ]; then
  sudo unlink /usr/bin/ld && sudo ln -s "$lld" /usr/bin/ld
fi

# Configure keyboard repeat in GNOME.
if [ "$GDMSESSION" == "gnome" ];  then
  echo "Configuring GNOME"
  gsettings set org.gnome.desktop.peripherals.keyboard delay 250
  gsettings set org.gnome.desktop.peripherals.keyboard repeat-interval 15
fi

