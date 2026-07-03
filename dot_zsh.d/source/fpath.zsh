if command -v brew &> /dev/null; then
    brew_prefix=$(brew --prefix)
    if [[ ":$FPATH:" != *":$brew_prefix/share/zsh/site-functions:"* ]]; then
        FPATH=$brew_prefix/share/zsh/site-functions:$FPATH
    fi
    if [[ ":$FPATH:" != *":$brew_prefix/share/zsh-completions:"* ]]; then
        FPATH=$brew_prefix/share/zsh-completions:$FPATH
    fi
    unset brew_prefix
fi

if [[ ":$FPATH:" != *":$HOME/.zfunc:"* ]]; then
    FPATH=$HOME/.zfunc:$FPATH
fi
