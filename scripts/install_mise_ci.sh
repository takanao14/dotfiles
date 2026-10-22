#!/usr/bin/env bash
# Install the setup-pinned mise binary on a disposable Linux CI runner.
set -euo pipefail

readonly destination="${1:?Usage: install_mise_ci.sh DESTINATION}"
source_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly source_root
readonly installer="$source_root/.chezmoiscripts/run_onchange_after_40_linux_mise.sh.tmpl"
case "$(uname -m)" in
    x86_64) arch=x64 ;;
    aarch64 | arm64) arch=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac
# Match the literal shell parameter expansion, without evaluating the template.
# shellcheck disable=SC2016
version="$(sed -n 's/^readonly MISE_VERSION="${MISE_VERSION:-\([^}]*\)}"$/\1/p' "$installer")"
checksum="$(awk -v arch="$arch" '
    /readonly MISE_ARCH=/ { selected = index($0, "\"" arch "\"") > 0 }
    selected && /readonly MISE_SHA256=/ {
        sub(/^.*MISE_SHA256="/, "")
        sub(/"$/, "")
        print
        exit
    }
' "$installer")"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
[[ "$checksum" =~ ^[0-9a-f]{64}$ ]]
curl -fsSL "https://github.com/jdx/mise/releases/download/v${version}/mise-v${version}-linux-${arch}" \
    -o "$destination"
echo "$checksum  $destination" | sha256sum --check
chmod 0755 "$destination"
