#!/usr/bin/env bash

# Automatically updates and rebuilds Swift. It can be particularly convenient
# for setting up a cron job.
#
# usage: update-swift.sh <scheme> <path>

readonly scheme=$1
readonly root=$2

# Make this low priority.
renice 19 -p $$ >/dev/null 2>&1
ionice -c3 -p $$ >/dev/null 2>&1

# Extend path for when running under cron.
export PATH=/usr/local/bin:$PATH

cd "$root" || exit

./swift/utils/update-checkout --scheme "$scheme"

$(dirname $BASH_SOURCE)/swift-lldb.sh
