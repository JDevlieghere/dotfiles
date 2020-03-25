#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") differential" >&2
    exit 1
fi

curl -L  "https://reviews.llvm.org/$1?download=true" > /tmp/patch
patch -f -p0 < /tmp/patch || patch -f -p1 < /tmp/patch
