#!/usr/bin/env bash

# if os is darwin
machine="$(uname)"
if [[ "$machine" == "Darwin" ]]; then
  echo "MacOS Initialize"
  if ! command -v brew &> /dev/null; then
    # homebrew installer
    echo "Homebrew Install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_line='eval "$(/opt/homebrew/bin/brew shellenv)"'
    grep -qF "$brew_line" "$HOME/.zprofile" 2>/dev/null || echo "$brew_line" >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if ! command -v chezmoi &> /dev/null; then
    echo "install chezmoi"
    brew install chezmoi
  fi

  chezmoi init --apply takanao14/dotfiles

elif [[ "$machine" == "Linux" ]]; then
  echo "Linux Initialize"

  # Detect Linux distribution
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$ID
  else
    distro="unknown"
  fi

  if [[ "$distro" == "ubuntu" ]] || [[ "$distro" == "debian" ]]; then
    pkgs=()
    command -v git &> /dev/null || pkgs+=(git)
    command -v zsh &> /dev/null || pkgs+=(zsh)
    [[ ${#pkgs[@]} -gt 0 ]] && sudo apt install -y "${pkgs[@]}"
  elif [[ "$distro" == "rocky" ]] || [[ "$distro" == "rhel" ]] || [[ "$distro" == "centos" ]] || [[ "$distro" == "fedora" ]]; then
    pkgs=()
    command -v git &> /dev/null || pkgs+=(git)
    command -v zsh &> /dev/null || pkgs+=(zsh)
    [[ ${#pkgs[@]} -gt 0 ]] && sudo dnf install -y "${pkgs[@]}"
  else
    echo "Unsupported Linux distribution: $distro"
    exit 1
  fi

  if ! command -v chezmoi &> /dev/null; then
    echo "install chezmoi"
    sh -c "$(curl -fsLS chezmoi.io/get)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
  fi

  chezmoi init --apply takanao14/dotfiles

fi
