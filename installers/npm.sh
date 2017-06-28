#!/usr/bin/env bash

if [ "$(uname)" == "Darwin" ]; then
  npm install -g ios-deploy
fi

npm install -g js-beautify
npm install -g remark-cli
npm install -g standard
