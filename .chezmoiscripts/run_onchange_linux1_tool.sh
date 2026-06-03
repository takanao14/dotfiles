#!/usr/bin/env bash
set -euo pipefail

[[ "$(uname)" == "Linux" ]] || exit 0

. /etc/os-release
readonly OS_ID="${ID}"

readonly BIN_DIR="$HOME/.local/bin"
readonly AQUA_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/aqua"

mkdir -p "$BIN_DIR"
export PATH="${AQUA_ROOT}/bin:${BIN_DIR}:${PATH}"

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

update_package_cache() {
    case "$OS_ID" in
        ubuntu) sudo apt-get update -qq ;;
        rocky)  sudo dnf makecache --refresh -q ;;
        *) log_error "Unsupported OS: ${OS_ID}"; exit 1 ;;
    esac
}

install_packages() {
    case "$OS_ID" in
        ubuntu) sudo apt-get install -y "$@" ;;
        rocky)  sudo dnf install -y "$@" ;;
        *) log_error "Unsupported OS: ${OS_ID}"; exit 1 ;;
    esac
}

add_apt_repository() {
    local repo_name="$1" gpg_url="$2" repo_line="$3"
    local keyring_path="/usr/share/keyrings/${repo_name}-keyring.gpg"
    log_info "Adding ${repo_name} repository..."
    curl -fsSL "$gpg_url" | gpg --dearmor | sudo tee "$keyring_path" > /dev/null
    sudo chmod 644 "$keyring_path"
    echo "$repo_line" | sudo tee "/etc/apt/sources.list.d/${repo_name}.list" > /dev/null
    sudo chmod 644 "/etc/apt/sources.list.d/${repo_name}.list"
}

add_dnf_repository() {
    local repo_name="$1" repo_url="$2" gpgkey_url="$3"
    log_info "Adding ${repo_name} repository..."
    sudo tee "/etc/yum.repos.d/${repo_name}.repo" > /dev/null <<EOF
[${repo_name}]
name=${repo_name}
baseurl=${repo_url}
enabled=1
gpgcheck=1
gpgkey=${gpgkey_url}
EOF
}

# ============================================================================
# aqua
# ============================================================================

install_aqua() {
    log_info "Installing aqua..."
    curl -sSfL https://raw.githubusercontent.com/aquaproj/aqua-installer/main/aqua-installer | bash
}

# ============================================================================
# HashiCorp Tools (managed via apt/dnf repository)
# ============================================================================

install_hashicorp_tools() {
    log_info "Installing HashiCorp tools (Terraform, Packer, Vault)..."
    update_package_cache
    case "$OS_ID" in
        ubuntu)
            install_packages gnupg software-properties-common
            . /etc/os-release
            local codename="${UBUNTU_CODENAME:-$(lsb_release -cs)}"
            add_apt_repository "hashicorp" \
                "https://apt.releases.hashicorp.com/gpg" \
                "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-keyring.gpg] https://apt.releases.hashicorp.com ${codename} main"
            ;;
        rocky)
            install_packages yum-utils
            sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
            ;;
    esac
    update_package_cache
    install_packages terraform packer vault
}

# ============================================================================
# OpenBao (managed via .deb/.rpm)
# ============================================================================

# renovate: datasource=github-releases depName=openbao/openbao
readonly OPENBAO_VERSION="${OPENBAO_VERSION:-2.5.4}"

install_openbao() {
    log_info "Installing openbao ${OPENBAO_VERSION}..."
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap "rm -rf '${tmp_dir}'" RETURN
    local bin_arch
    bin_arch="$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"
    case "$OS_ID" in
        ubuntu)
            local pkg_name="openbao_${OPENBAO_VERSION}_linux_${bin_arch}.deb"
            curl -fsSL "https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/${pkg_name}" \
                -o "${tmp_dir}/${pkg_name}"
            sudo dpkg -i "${tmp_dir}/${pkg_name}"
            ;;
        rocky)
            local pkg_name="openbao_${OPENBAO_VERSION}_linux_${bin_arch}.rpm"
            curl -fsSL "https://github.com/openbao/openbao/releases/download/v${OPENBAO_VERSION}/${pkg_name}" \
                -o "${tmp_dir}/${pkg_name}"
            sudo rpm -i "${tmp_dir}/${pkg_name}"
            ;;
    esac
}

# ============================================================================
# Helm plugins
# ============================================================================

install_helm_diff_plugin() {
    if helm plugin list 2>/dev/null | grep -q "^diff"; then
        log_info "helm-diff plugin is already installed, skipping"
        return
    fi
    log_info "Installing helm-diff plugin..."
    helm plugin install --verify=false https://github.com/databus23/helm-diff
}

# ============================================================================
# Main
# ============================================================================

main() {
    log_info "=== Linux Development Tools Installation ==="

    # aqua
    if ! command -v aqua &>/dev/null; then
        install_aqua
    fi
    log_info "Installing tools via aqua..."
    aqua install --all

    # HashiCorp (apt/dnf repository)
    if ! command -v terraform &>/dev/null || ! command -v packer &>/dev/null || ! command -v vault &>/dev/null; then
        install_hashicorp_tools
    fi

    # OpenBao (.deb/.rpm)
    if ! command -v bao &>/dev/null; then
        install_openbao
    fi

    install_helm_diff_plugin

    log_info "=== Installation completed ==="
}

main
