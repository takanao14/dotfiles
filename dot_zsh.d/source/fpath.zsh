# Keep the first occurrence of each directory when paths are prepended below.
# In particular, `brew shellenv` prepends its site-functions directory in login
# shells, so merely checking whether ~/.zfunc already exists is insufficient.
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
