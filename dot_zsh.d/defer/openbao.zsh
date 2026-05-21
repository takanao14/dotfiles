# bashcompinit is loaded in source/bashcompinit.zsh
if command -v bao &> /dev/null; then
    complete -o nospace -C "$(command -v bao)" bao
fi
