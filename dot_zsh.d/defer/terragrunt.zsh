autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C $(brew --prefix)/bin/terragrunt terragrunt
