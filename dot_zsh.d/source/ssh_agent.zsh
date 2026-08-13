# Prefer a forwarded 1Password agent; otherwise use the local systemd agent.
# A stable symlink keeps reattached tmux panes off stale session sockets.
# Each new shell repoints the link, so the latest connection wins.

if [[ "$OSTYPE" == linux* ]]; then
  _agent_link="$HOME/.ssh/agent_sock"
  _agent_local="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.socket"

  if [[ -S "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$_agent_link" ]]; then
    # A live externally-provided socket (agent forwarding): adopt it.
    ln -sf "$SSH_AUTH_SOCK" "$_agent_link"
  else
    if [[ ! -S "$_agent_local" ]] && command -v systemctl >/dev/null 2>&1; then
      systemctl --user start ssh-agent.service >/dev/null 2>&1
    fi
    if [[ -S "$_agent_local" ]]; then
      # Ignore forwarded sockets inherited from another session.
      ln -sf "$_agent_local" "$_agent_link"
    fi
  fi

  if [[ -S "$_agent_link" ]]; then
    export SSH_AUTH_SOCK="$_agent_link"
  fi
  unset _agent_link _agent_local
fi
