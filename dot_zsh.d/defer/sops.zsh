export SOPS_AGE_KEY_FILE=$HOME/.config/sops/age/keys.txt

if command -v sops &> /dev/null; then
  eval "$(sops completion zsh)"
fi
