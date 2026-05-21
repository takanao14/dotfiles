# bashcompinit is loaded in source/bashcompinit.zsh
if command -v terraform &> /dev/null; then
    complete -o nospace -C "$(command -v terraform)" terraform
fi
