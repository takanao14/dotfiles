#!/usr/bin/env zsh

[[ "$(uname)" == "Darwin" ]] || exit 0

echo "macos script"

if ! command -v brew &> /dev/null; then
  echo "Homebrew is not installed; skipping brew bundle"
  exit 0
fi

brew bundle --global
