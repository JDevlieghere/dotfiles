#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Usage: $(basename "$0") differential" >&2
    exit 1
fi

curl -L  "https://reviews.llvm.org/$1?download=true" | patch -p0
