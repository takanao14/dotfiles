#!/usr/bin/env bash
set -euo pipefail

readonly DOTFILES_REPOSITORY="takanao14/dotfiles"

brew_shellenv() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
        /opt/homebrew/bin/brew shellenv
    elif [[ -x /usr/local/bin/brew ]]; then
        /usr/local/bin/brew shellenv
    fi
}

brew_path() {
    if [[ -x /opt/homebrew/bin/brew ]]; then
        printf '%s\n' /opt/homebrew/bin/brew
    elif [[ -x /usr/local/bin/brew ]]; then
        printf '%s\n' /usr/local/bin/brew
    fi
}

initialize_macos() {
    echo "macOS Initialize"

    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew Install"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        local brew_line
        brew_line="eval \"\$($(brew_path) shellenv)\""
        grep -qF "$brew_line" "$HOME/.zprofile" 2>/dev/null || echo "$brew_line" >> "$HOME/.zprofile"
        eval "$(brew_shellenv)"
    fi

    if ! command -v chezmoi >/dev/null 2>&1; then
        echo "install chezmoi"
        brew install chezmoi
    fi

    chezmoi init --apply "$DOTFILES_REPOSITORY"
}

detect_linux_distribution() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        printf '%s\n' "${ID:-unknown}"
    else
        printf '%s\n' unknown
    fi
}

refresh_hashicorp_apt_key_if_configured() {
    local distro="$1"
    [[ "$distro" == "ubuntu" || "$distro" == "debian" ]] || return 0

    local source_file
    for source_file in \
        /etc/apt/sources.list \
        /etc/apt/sources.list.d/*.list \
        /etc/apt/sources.list.d/*.sources; do
        [[ -r "$source_file" ]] || continue
        grep -qF 'apt.releases.hashicorp.com' "$source_file" || continue

        if ! command -v gpg >/dev/null 2>&1; then
            printf 'Cannot refresh the configured HashiCorp APT key: gpg is not installed.\n' >&2
            exit 1
        fi

        echo "Refresh HashiCorp APT signing key"
        curl -fsSL https://apt.releases.hashicorp.com/gpg \
            | gpg --dearmor \
            | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
        sudo chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg
        return 0
    done
}

install_linux_bootstrap_packages() {
    local distro="$1"
    local command_name
    local -a packages=()

    for command_name in git make zsh; do
        command -v "$command_name" >/dev/null 2>&1 || packages+=("$command_name")
    done

    [[ ${#packages[@]} -gt 0 ]] || return 0

    case "$distro" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y "${packages[@]}"
            ;;
        rocky)
            sudo dnf install -y "${packages[@]}"
            ;;
        *)
            printf 'Unsupported Linux distribution: %s\n' "$distro" >&2
            exit 1
            ;;
    esac
}

initialize_linux() {
    echo "Linux Initialize"

    local distro
    distro="$(detect_linux_distribution)"

    case "$distro" in
        ubuntu|debian|rocky) ;;
        *)
            printf 'Unsupported Linux distribution: %s\n' "$distro" >&2
            exit 1
            ;;
    esac

    # A rotated third-party key must be repaired before the first apt update.
    refresh_hashicorp_apt_key_if_configured "$distro"
    install_linux_bootstrap_packages "$distro"

    if ! command -v chezmoi >/dev/null 2>&1; then
        echo "install chezmoi"
        sh -c "$(curl -fsLS chezmoi.io/get)" -- -b "$HOME/.local/bin"
        export PATH="$HOME/.local/bin:$PATH"
    fi

    chezmoi init --apply "$DOTFILES_REPOSITORY"
}

main() {
    case "$(uname -s)" in
        Darwin)
            initialize_macos
            ;;
        Linux)
            initialize_linux
            ;;
        *)
            printf 'Unsupported OS: %s\n' "$(uname -s)" >&2
            exit 1
            ;;
    esac
}

main "$@"
