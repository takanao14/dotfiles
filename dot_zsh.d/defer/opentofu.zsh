if command -v tofu &> /dev/null; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C "$(command -v tofu)" tofu
fi
