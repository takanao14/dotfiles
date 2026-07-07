# SSH agent socket selection for headless Linux hosts (toolbox1).
#
# Two entry paths coexist on this host:
#   - Mac (ForwardAgent yes): sshd provides a per-session forwarded socket
#     backed by the 1Password agent; private keys never touch this host.
#   - iOS clients (no agent forwarding): fall back to the local systemd user
#     ssh-agent (~/.config/systemd/user/ssh-agent.service) holding this
#     host's own key.
#
# SSH_AUTH_SOCK always ends up pointing at the stable symlink
# ~/.ssh/agent_sock. Forwarded sockets live at per-session /tmp paths that
# die with the connection, so tmux panes reattached from another device
# would otherwise hold a dead socket; the symlink is repointed on each new
# shell instead. Last connection wins.

if [[ "$OSTYPE" == linux* ]]; then
  _agent_link="$HOME/.ssh/agent_sock"
  _agent_local="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent.socket"

  if [[ -S "$SSH_AUTH_SOCK" && "$SSH_AUTH_SOCK" != "$_agent_link" ]]; then
    # A live externally-provided socket (agent forwarding): adopt it.
    ln -sf "$SSH_AUTH_SOCK" "$_agent_link"
  elif [[ ! -S "$_agent_link" && -S "$_agent_local" ]]; then
    # Nothing live behind the link (no forwarding, or that session ended):
    # fall back to the local agent.
    ln -sf "$_agent_local" "$_agent_link"
  fi

  if [[ -S "$_agent_link" ]]; then
    export SSH_AUTH_SOCK="$_agent_link"
  fi
  unset _agent_link _agent_local
fi
