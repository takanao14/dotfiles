#!/usr/bin/env bash
set -euo pipefail

# Chezmoi scripts run in separate processes, so the mise installer cannot
# update this script's PATH. Prefer per-user tools over a golden-image baseline.
for mise_shims in /usr/local/share/mise/shims "$HOME/.local/share/mise/shims"; do
    if [[ -d "$mise_shims" && ":$PATH:" != *":$mise_shims:"* ]]; then
        PATH="$mise_shims:$PATH"
    fi
done
export PATH
unset mise_shims

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

    # compinit requires #compdef on the first line.
    awk 'seen || NF { seen = 1; print }' "$raw_file" > "$generated_file"

    # Invoke a differently named entrypoint after the initial autoload.
    if [[ -n "$autoload_entrypoint" ]]; then
        printf '\n%s "$@"\n' "$autoload_entrypoint" >> "$generated_file"
    fi

    if [[ -f "$destination" ]] && cmp -s "$generated_file" "$destination"; then
        return
    fi

    install -m 0644 "$generated_file" "$destination"
    echo "Updated zsh completion: ${destination}"
}

generate_ansible_completion() {
    local command_name="$1"
    local output_name="_$1"
    local command_path interpreter

    command_path="$(command -v "$command_name" 2>/dev/null)" || {
        echo "Skipping ${command_name} completion: command not found"
        return
    }
    interpreter="$(head -n 1 "$command_path")"
    interpreter="${interpreter#\#!}"

    if [[ -x "$interpreter" ]] &&
        "$interpreter" -c 'import argcomplete' >/dev/null 2>&1; then
        generate_completion register-python-argcomplete "$output_name" '' \
            register-python-argcomplete --shell zsh "$command_name"
        return
    fi

    local generated_file="${TMP_DIR}/${output_name}"
    local destination="${ZFUNC_DIR}/${output_name}"
    cat > "$generated_file" <<EOF
#compdef ${command_name}
if [[ \$PREFIX == -* ]]; then
    local -a cli_options
    cli_options=(\${(f)"\$(command ${command_name} --help 2>/dev/null | grep -Eo -- '-{1,2}[[:alnum:]][[:alnum:]-]*' | sort -u)"})
    _describe 'options' cli_options
else
    _files
fi
EOF
    if [[ ! -f "$destination" ]] || ! cmp -s "$generated_file" "$destination"; then
        install -m 0644 "$generated_file" "$destination"
        echo "Updated zsh completion: ${destination}"
    fi
}

use_zsh_ansible_completion() {
    command -v zsh >/dev/null 2>&1 || return 1
    zsh -f -c '
        for dir in $fpath; do
            [[ $dir == $HOME/.zfunc ]] && continue
            [[ -f $dir/_ansible ]] || continue
            head -n 1 "$dir/_ansible" | grep -Eq "^#compdef .*ansible-playbook"
            exit $?
        done
        exit 1
    '
}

remove_generated_ansible_completion() {
    local command_name="$1"
    local destination="${ZFUNC_DIR}/_${command_name}"
    [[ -f "$destination" ]] || return 0

    if head -n 1 "$destination" | grep -Fxq "#compdef ${command_name}" &&
        { grep -Fq '__python_argcomplete_run()' "$destination" ||
          grep -Fq "_describe 'options' cli_options" "$destination"; }; then
        rm -f "$destination"
        echo "Removed generated zsh completion: ${destination}"
    else
        echo "Keeping unrecognized zsh completion: ${destination}" >&2
    fi
}

# Shell tools
generate_completion sheldon  _sheldon  '' sheldon completions --shell zsh
generate_completion starship _starship '' starship completions zsh
generate_completion zellij   _zellij   '' zellij setup --generate-completion zsh

# Kubernetes and infrastructure tools
generate_completion kubectl  _kubectl  '' kubectl completion zsh
generate_completion helm     _helm     '' helm completion zsh
generate_completion argocd   _argocd   '' argocd completion zsh
generate_completion kubie    _kubie    '' kubie generate-completion zsh
generate_completion k9s      _k9s      '' k9s completion zsh
generate_completion helmfile _helmfile '' helmfile completion zsh
generate_completion k0sctl   _k0sctl   _k0sctl_zsh_autocomplete k0sctl completion zsh
generate_completion cilium   _cilium   '' cilium completion zsh

# Other manually installed tools
generate_completion gh         _gh         '' gh completion -s zsh
generate_completion bat        _bat        '' bat --completion zsh
generate_completion rg         _rg         '' rg --generate complete-zsh
generate_completion procs      _procs      '' procs --gen-completion-out zsh
generate_completion sops       _sops       _cli_zsh_autocomplete sops completion zsh
generate_completion dnscontrol _dnscontrol '' dnscontrol shell-completion zsh
generate_completion rclone     _rclone     '' rclone completion zsh -
generate_completion uv         _uv         '' uv generate-shell-completion zsh
if use_zsh_ansible_completion; then
    remove_generated_ansible_completion ansible
    remove_generated_ansible_completion ansible-playbook
else
    generate_ansible_completion ansible
    generate_ansible_completion ansible-playbook
fi
generate_ansible_completion ansible-lint

# compinit's dump does not track content changes to individual completion
# files. Remove it after generation so the next shell scans ~/.zfunc again.
rm -f "${ZDOTDIR:-$HOME}"/.zcompdump*
