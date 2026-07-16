#!/usr/bin/env bash
set -euo pipefail

readonly ZFUNC_DIR="$HOME/.zfunc"
readonly TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$ZFUNC_DIR"

generate_completion() {
    local command_name="$1"
    local output_name="$2"
    shift 2

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Skipping ${command_name} completion: command not found"
        return
    fi

    local generated_file="${TMP_DIR}/${output_name}"
    local destination="${ZFUNC_DIR}/${output_name}"
    "$@" > "$generated_file"

    if [[ -f "$destination" ]] && cmp -s "$generated_file" "$destination"; then
        return
    fi

    install -m 0644 "$generated_file" "$destination"
    echo "Updated zsh completion: ${destination}"
}

generate_completion sops _sops sops completion zsh
