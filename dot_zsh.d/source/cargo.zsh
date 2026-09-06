_cargo_home="${CARGO_HOME:-$HOME/.cargo}"

if [[ -d "$_cargo_home/bin" && ":$PATH:" != *":$_cargo_home/bin:"* ]]; then
  export PATH="$_cargo_home/bin:$PATH"
fi

unset _cargo_home
