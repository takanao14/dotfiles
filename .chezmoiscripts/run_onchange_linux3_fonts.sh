#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname)" == "Linux" ]] || exit 0

. /etc/os-release
readonly OS_ID="${ID}"

# renovate: datasource=github-releases depName=yuru7/udev-gothic
readonly UDEV_GOTHIC_VERSION="${UDEV_GOTHIC_VERSION:-2.2.0}"
readonly FONTS_DIR="$HOME/.local/share/fonts/udev-gothic"
readonly DOWNLOAD_URL="https://github.com/yuru7/udev-gothic/releases/download/v${UDEV_GOTHIC_VERSION}/UDEVGothic_NF_v${UDEV_GOTHIC_VERSION}.zip"

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

check_dependencies() {
    local missing_deps=()
    for cmd in curl unzip fc-cache fc-list; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        case "$OS_ID" in
            ubuntu) log_info "Install them with: sudo apt-get install -y fontconfig unzip curl" ;;
            rocky)  log_info "Install them with: sudo dnf install -y fontconfig unzip curl" ;;
        esac
        return 1
    fi
}

is_font_installed() {
    local cache_file="$HOME/.local/share/chezmoi-versions/udev-gothic"
    [[ "$(cat "$cache_file" 2>/dev/null)" == "$UDEV_GOTHIC_VERSION" ]] && \
        fc-list : family | grep -q "UDEV Gothic NF"
}

download_and_extract_font() {
    local tmp_dir="$1" zip_file="$1/udev-gothic.zip"
    log_info "Downloading UDEV Gothic NF ${UDEV_GOTHIC_VERSION}..."
    curl -fsSL --retry 3 --retry-delay 2 "$DOWNLOAD_URL" -o "$zip_file"
    log_info "Extracting fonts..."
    unzip -q "$zip_file" -d "$tmp_dir"
}

install_font_files() {
    local tmp_dir="$1"
    log_info "Installing font files to ${FONTS_DIR}..."
    mkdir -p "$FONTS_DIR"
    find "$tmp_dir" -type f \( -name "*.ttf" -o -name "*.otf" \) -exec cp {} "$FONTS_DIR/" \;
}

rebuild_font_cache() {
    log_info "Rebuilding font cache..."
    fc-cache -f "$FONTS_DIR"
}

install_udev_gothic() {
    log_info "Installing UDEV Gothic NF font..."
    if is_font_installed; then
        log_info "UDEV Gothic NF ${UDEV_GOTHIC_VERSION} is already installed"
        return 0
    fi
    check_dependencies
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap "rm -rf '$tmp_dir'" RETURN
    download_and_extract_font "$tmp_dir"
    install_font_files "$tmp_dir"
    rebuild_font_cache
    mkdir -p "$HOME/.local/share/chezmoi-versions"
    echo "$UDEV_GOTHIC_VERSION" > "$HOME/.local/share/chezmoi-versions/udev-gothic"
    log_info "UDEV Gothic NF installed successfully"
}

main() {
    log_info "=== Font Installation Script ==="
    check_gui "Skipping font installation"
    install_udev_gothic
    log_info "=== Font installation completed ==="
}

main "$@"
