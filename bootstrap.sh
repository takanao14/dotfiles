#!/usr/bin/env bash

# if os is darwin
machine="$(uname)"
if [[ "$machine" == "Darwin" ]]; then
  echo "MacOS Initialize"
  if ! command -v brew &> /dev/null; then
    # homebrew installer
    echo "Homebrew Install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if ! command -v chezmoi &> /dev/null; then
    echo "install chezmoi"
    brew install chezmoi
  fi

elif [[ "$machine" == "Linux" ]]; then
  echo "Linux"

  if ! command -v zsh &> /dev/null; then
    echo "install zsh"
    sudo apt install zsh -y
  fi

  if ! command -v chezmoi &> /dev/null; then
    echo "install chezmoi"
    sh -c "$(curl -fsLS chezmoi.io/get)" -- -b $HOME/.local/bin
  fi

fi
