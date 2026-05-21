# bashcompinit is loaded in source/bashcompinit.zsh
if command -v terragrunt &> /dev/null; then
    complete -o nospace -C "$(command -v terragrunt)" terragrunt
fi
