#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname)" == "Linux" ]] || exit 0

# renovate: datasource=github-releases depName=kovidgoyal/kitty
readonly KITTY_VERSION="${KITTY_VERSION:-0.40.0}"

readonly BIN_DIR="$HOME/.local/bin"
readonly VERSION_CACHE_DIR="$HOME/.local/share/tool-versions"

# ============================================================================
# Logging
# ============================================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# ============================================================================
# Helpers
# ============================================================================

check_gui() {
    local skip_msg="${1:-}"
    log_info "Checking system requirements..."
    local has_gui=false
    if systemctl is-active --quiet xrdp 2>/dev/null; then
        log_info "xrdp service detected"
        has_gui=true
    fi
    if pgrep -E "^(weston|sway|wayfire|labwc|river|hyprland)$" >/dev/null 2>&1; then
        log_info "Wayland compositor detected"
        has_gui=true
    fi
    if [[ "$has_gui" == "false" ]]; then
        log_warn "No GUI session detected (xrdp or Wayland required)"
        [[ -n "$skip_msg" ]] && log_warn "$skip_msg"
        exit 0
    fi
}

# ============================================================================
# Kitty
# ============================================================================

install_kitty() {
    log_info "Installing kitty ${KITTY_VERSION}..."

    local arch
    case "$(uname -m)" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="arm64" ;;
        *) log_error "Unsupported architecture: $(uname -m)"; exit 1 ;;
    esac

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap "rm -rf '${tmp_dir}'" RETURN

    curl -fsSL "https://github.com/kovidgoyal/kitty/releases/download/v${KITTY_VERSION}/kitty-${KITTY_VERSION}-${arch}.txz" \
        -o "${tmp_dir}/kitty.txz"

    rm -rf "$HOME/.local/kitty.app"
    mkdir -p "$HOME/.local/kitty.app"
    tar xJf "${tmp_dir}/kitty.txz" -C "$HOME/.local/kitty.app"

    mkdir -p "$BIN_DIR"
    ln -sf "$HOME/.local/kitty.app/bin/kitty"  "$BIN_DIR/kitty"
    ln -sf "$HOME/.local/kitty.app/bin/kitten" "$BIN_DIR/kitten"

    mkdir -p "$HOME/.local/share/applications"
    cp "$HOME/.local/kitty.app/share/applications/kitty.desktop" \
        "$HOME/.local/share/applications/kitty.desktop"
    sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
        "$HOME/.local/share/applications/kitty.desktop"

    mkdir -p "$VERSION_CACHE_DIR"
    echo "$KITTY_VERSION" > "$VERSION_CACHE_DIR/kitty"

    log_info "kitty ${KITTY_VERSION} installed"
}

main() {
    log_info "=== Terminal Installation Script ==="

    check_gui "Skipping kitty installation"

    local cache_file="$VERSION_CACHE_DIR/kitty"
    if command -v kitty &>/dev/null && \
       [[ "$(cat "$cache_file" 2>/dev/null)" == "$KITTY_VERSION" ]]; then
        log_info "kitty ${KITTY_VERSION} is already up to date, skipping"
        exit 0
    fi

    install_kitty

    log_info "=== Installation completed successfully ==="
}

main "$@"
