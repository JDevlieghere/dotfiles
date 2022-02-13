#!/usr/bin/env bash

if [ "$#" -eq 0 ] ; then
  python=python3
else
  python=$*
fi

# Make sure we have the latest version
$python -m pip install --upgrade pip

# Install packages
$python -m pip install --upgrade autopep8
$python -m pip install --upgrade gprof2dot
$python -m pip install --upgrade neovim
$python -m pip install --upgrade pyflakes
$python -m pip install --upgrade pylint
$python -m pip install --upgrade python-language-server
$python -m pip install --upgrade rich
$python -m pip install --upgrade sphinx
$python -m pip install --upgrade yapf
