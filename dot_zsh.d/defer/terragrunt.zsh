if command -v terragrunt &> /dev/null; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C "$(command -v terragrunt)" terragrunt
fi
