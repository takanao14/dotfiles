# bashcompinit is loaded in source/bashcompinit.zsh
if command -v tofu &> /dev/null; then
    complete -o nospace -C "$(command -v tofu)" tofu
fi
