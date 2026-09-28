# Shared PATH setup, sourced by ~/.zshrc and ~/.bashrc. Keep it POSIX sh.

case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac

if [ "$(uname)" = "Linux" ]; then
  # Add system first because each entry is prepended; user shims must win.
  for _mise_path in /usr/local/share/mise/shims "$HOME/.local/share/mise/shims"; do
    if [ -d "$_mise_path" ]; then
      case ":$PATH:" in
        *":$_mise_path:"*) ;;
        *) PATH="$_mise_path:$PATH" ;;
      esac
    fi
  done
  unset _mise_path

  if [ -z "${HELM_PLUGINS:-}" ] && [ -d /usr/local/share/helm/plugins ]; then
    export HELM_PLUGINS=/usr/local/share/helm/plugins
  fi
fi

export PATH
