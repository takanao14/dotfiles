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
  echo "Linux Initialize"

  # Detect Linux distribution
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
  else
    distro="unknown"
  fi

  if ! command -v zsh &> /dev/null; then
    echo "install zsh"
    if [[ "$distro" == "ubuntu" ]] || [[ "$distro" == "debian" ]]; then
      sudo apt install zsh -y
    elif [[ "$distro" == "rocky" ]] || [[ "$distro" == "rhel" ]] || [[ "$distro" == "centos" ]] || [[ "$distro" == "fedora" ]]; then
      sudo dnf install zsh -y
    else
      echo "Unsupported Linux distribution: $distro"
      exit 1
    fi
  fi

  if ! command -v chezmoi &> /dev/null; then
    echo "install chezmoi"
    sh -c "$(curl -fsLS chezmoi.io/get)" -- -b $HOME/.local/bin
  fi

fi
