ssh() {
  if [[ "${TERM:-}" == "xterm-kitty" || "${TERM:-}" == "xterm-ghostty" ]]; then
    TERM=xterm-256color command ssh "$@"
  else
    command ssh "$@"
  fi
}
