#!/usr/bin/env bash

sudo scutil --set HostName $1
sudo scutil --set LocalHostName $1
sudo scutil --set ComputerName $1
dscacheutil -flushcache
