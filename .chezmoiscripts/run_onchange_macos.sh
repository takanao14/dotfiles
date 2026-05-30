#!/usr/bin/env zsh

[[ "$(uname)" == "Darwin" ]] || exit 0

echo "macos script"
brew bundle --global
