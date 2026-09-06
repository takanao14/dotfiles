_cargo_home="${CARGO_HOME:-$HOME/.cargo}"

if [[ -d "$_cargo_home/bin" && ":$PATH:" != *":$_cargo_home/bin:"* ]]; then
  export PATH="$_cargo_home/bin:$PATH"
fi

# Homebrew ships rustup keg-only, so its cargo/rustc proxies stay out of the
# main bin directory. Prepend them ahead of any stale proxies in CARGO_HOME.
_rustup_bin="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/rustup/bin"

if [[ -d "$_rustup_bin" && ":$PATH:" != *":$_rustup_bin:"* ]]; then
  export PATH="$_rustup_bin:$PATH"
fi

unset _cargo_home _rustup_bin
