if command -v brew &> /dev/null; then
    if [[ ":$FPATH:" != *":$(brew --prefix)/share/zsh/site-functions:"* ]]; then
        FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
    fi
    if [[ ":$FPATH:" != *":$(brew --prefix)/share/zsh-completions:"* ]]; then
        FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
    fi
fi

if [[ ":$FPATH:" != *":$HOME/.zfunc:"* ]]; then
    FPATH=$HOME/.zfunc:$FPATH
fi
