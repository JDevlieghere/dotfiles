#!/usr/bin/env bash

# Inspired by https://mths.be/macos

# --------------------------------------------------------------------------- #
# Developer Mode                                                              #
# --------------------------------------------------------------------------- #

sudo dseditgroup -o edit -a jonas -t user _developer
sudo DevToolsSecurity -enable > /dev/null

# --------------------------------------------------------------------------- #
# Power Management Settings                                                   #
# --------------------------------------------------------------------------- #

# Automatic restart on power loss
sudo pmset -a autorestart 1

# Set the display sleep to 15 minutes
sudo pmset -a displaysleep 15

# Disable machine sleep while charging
sudo pmset -c sleep 0

# Set machine sleep to 5 minutes on battery
sudo pmset -b sleep 5

# --------------------------------------------------------------------------- #
# System Settings                                                             #
# --------------------------------------------------------------------------- #

# Automatically restart after the system freezes
sudo systemsetup -setrestartfreeze on > /dev/null

# Automatically restart after a power failure
sudo systemsetup -setrestartpowerfailure on > /dev/null

# --------------------------------------------------------------------------- #
# Dock                                                                        #
# --------------------------------------------------------------------------- #

# Set the icon size of Dock items to 32 pixels
defaults write com.apple.dock tilesize -int 32

# Enable magnification
defaults write com.apple.dock magnification -int 1;

# Set the icon size of Dock items when magnified to 96 pixels
defaults write com.apple.dock largesize -int 96

# --------------------------------------------------------------------------- #
# Activity Monitor                                                            #
# --------------------------------------------------------------------------- #

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# --------------------------------------------------------------------------- #
# Finder                                                                      #
# --------------------------------------------------------------------------- #

# Disable animations
defaults write com.apple.finder DisableAllAnimations -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Use list view in all Finder windows by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Expand the following "General" and "Open With" File Info panes
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
	OpenWith -bool true

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --------------------------------------------------------------------------- #
# Screensaver                                                                 #
# --------------------------------------------------------------------------- #

# Immediately require password after screen saver or sleep
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

# --------------------------------------------------------------------------- #
# Keyboard and Mouse                                                          #
# --------------------------------------------------------------------------- #

# Disable smart quotes and dashes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Increase keyboard repeat rate
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain KeyRepeat -int 1

# Disable mouse acceleration
defaults write NSGlobalDomain com.apple.mouse.scaling -1

# --------------------------------------------------------------------------- #
# Various UI/UX                                                               #
# --------------------------------------------------------------------------- #

# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Enable spring loading for directories but remove the delay
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Turn off the “Application Downloaded from Internet” quarantine warning.
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Disable Resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false

# --------------------------------------------------------------------------- #
# Gatekeeper                                                                  #
# --------------------------------------------------------------------------- #

xattr -rd com.apple.quarantine /Applications/Alacritty.app

# --------------------------------------------------------------------------- #
# Pinentry                                                                    #
# --------------------------------------------------------------------------- #
defaults write org.gpgtools.common UseKeychain -bool true
