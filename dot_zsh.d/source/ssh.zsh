ssh() {
  if [[ "${TERM:-}" == "xterm-kitty" ]]; then
    TERM=xterm-256color command ssh "$@"
  else
    command ssh "$@"
  fi
}
