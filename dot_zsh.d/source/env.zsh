if [[ -f "$HOME/.env" ]]; then
  _load_dotenv() {
    setopt local_options allexport
    source "$HOME/.env"
  }
  _load_dotenv
  unfunction _load_dotenv
fi
