#!/usr/bin/env bash
set -euo pipefail

# if os is darwin
machine="$(uname)"

brew_shellenv() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    /opt/homebrew/bin/brew shellenv
  elif [[ -x /usr/local/bin/brew ]]; then
    /usr/local/bin/brew shellenv
  fi
}

brew_path() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    echo /opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    echo /usr/local/bin/brew
  fi
}

if [[ "$machine" == "Darwin" ]]; then
  echo "MacOS Initialize"
  if ! command -v brew &> /dev/null; then
    # homebrew installer
    echo "Homebrew Install"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew_line="eval \"\$($(brew_path) shellenv)\""
    grep -qF "$brew_line" "$HOME/.zprofile" 2>/dev/null || echo "$brew_line" >> "$HOME/.zprofile"
    eval "$(brew_shellenv)"
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
    # shellcheck disable=SC1091
    . /etc/os-release
    distro=${ID:-unknown}
  else
    distro="unknown"
  fi

  if [[ "$distro" == "ubuntu" ]] || [[ "$distro" == "debian" ]]; then
    pkgs=()
    command -v git &> /dev/null || pkgs+=(git)
    command -v zsh &> /dev/null || pkgs+=(zsh)
    if [[ ${#pkgs[@]} -gt 0 ]]; then
      sudo apt-get update
      sudo apt-get install -y "${pkgs[@]}"
    fi
  elif [[ "$distro" == "rocky" ]]; then
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

else
  echo "Unsupported OS: $machine" >&2
  exit 1
fi
