#!/usr/bin/env bash
set -euo pipefail

readonly ZFUNC_DIR="$HOME/.zfunc"
TMP_DIR="$(mktemp -d)"
readonly TMP_DIR
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$ZFUNC_DIR"

generate_completion() {
    local command_name="$1"
    local output_name="$2"
    local autoload_entrypoint="$3"
    shift 3

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Skipping ${command_name} completion: command not found"
        return
    fi

    local raw_file="${TMP_DIR}/${output_name}.raw"
    local generated_file="${TMP_DIR}/${output_name}"
    local destination="${ZFUNC_DIR}/${output_name}"
    "$@" > "$raw_file"

    # compinit only recognizes #compdef when it is on the first line. Some CLI
    # generators emit leading blank lines because their output is intended to
    # be sourced directly rather than installed as an autoload function.
    awk 'seen || NF { seen = 1; print }' "$raw_file" > "$generated_file"

    # A generated file can register a differently named completion function
    # when sourced. As an autoloaded _<command> function it must also invoke
    # that entrypoint for the completion request that caused the initial load.
    if [[ -n "$autoload_entrypoint" ]]; then
        printf '\n%s "$@"\n' "$autoload_entrypoint" >> "$generated_file"
    fi

    if [[ -f "$destination" ]] && cmp -s "$generated_file" "$destination"; then
        return
    fi

    install -m 0644 "$generated_file" "$destination"
    echo "Updated zsh completion: ${destination}"
}

generate_completion sops _sops _cli_zsh_autocomplete sops completion zsh

# compinit's dump does not track content changes to individual completion
# files. Remove it after generation so the next shell scans ~/.zfunc again.
rm -f "${ZDOTDIR:-$HOME}"/.zcompdump*
