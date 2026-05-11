if command -v bao &> /dev/null; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C "$(command -v bao)" bao
fi
