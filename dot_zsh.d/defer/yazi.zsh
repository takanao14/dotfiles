if command -v yazi >/dev/null 2>&1; then
  # Return to the directory selected in Yazi without running it at shell startup.
  y() {
    local tmp cwd result
    tmp="$(mktemp "${TMPDIR:-/tmp}/yazi-cwd.XXXXXX")" || return
    {
      if command yazi "$@" --cwd-file="$tmp"; then
        result=0
        IFS= read -r -d '' cwd < "$tmp" || true
        if [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
          builtin cd -- "$cwd"
        fi
      else
        result=$?
      fi
    } always {
      command rm -f -- "$tmp"
    }
    return "$result"
  }
  compdef _yazi y
fi
