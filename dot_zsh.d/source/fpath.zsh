# Deduplicate paths after `brew shellenv` prepends its site-functions directory.
typeset -gU fpath

if command -v brew &> /dev/null; then
    brew_prefix=$(brew --prefix)
    fpath=(
        "$brew_prefix/share/zsh/site-functions"
        "$brew_prefix/share/zsh-completions"
        $fpath
    )
    unset brew_prefix
fi

fpath=("$HOME/.zfunc" $fpath)
