# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports macOS and Linux (Ubuntu / Debian / Rocky Linux).

Linux tool installation requires Python 3.12 or newer for the pinned Ansible
toolchain. Use a release or configured package repository that provides
`python3.12` when the distribution default is older.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/takanao14/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` automatically runs the following:

1. Install Homebrew (macOS) / zsh and git (Linux)
2. Install chezmoi
3. Apply this repository via `chezmoi init --apply takanao14/dotfiles`

## Structure

```
dotfiles/
├── bootstrap.sh                   # Setup script for new machines
├── dot_Brewfile                   # Homebrew package list (macOS)
├── dot_gitconfig.tmpl             # ~/.gitconfig (email templated per machine)
├── dot_zshrc                      # ~/.zshrc
├── dot_zprofile                   # ~/.zprofile (Homebrew path config)
├── dot_tmux.conf                  # ~/.tmux.conf
├── .chezmoi.toml.tmpl             # chezmoi data (1Password detection, prompted email)
├── dot_zsh.d/
│   ├── source/                    # Loaded immediately at zsh startup
│   │   ├── editor.zsh             # Editor environment variable
│   │   ├── fpath.zsh              # Completion path configuration
│   │   ├── ssh.zsh                # SSH TERM fallback for kitty
│   │   └── starship.zsh           # Starship prompt initialization
│   └── defer/                     # Lazily loaded via zsh-defer
│       ├── alias.zsh              # Aliases (kubectl, etc.)
│       ├── direnv.zsh             # direnv hook
│       ├── zoxide.zsh             # zoxide initialization
│       ├── sops.zsh               # SOPS age key environment variable
│       ├── orbstack.zsh           # OrbStack shell init (Linux VMs)
│       ├── krew.zsh               # kubectl krew path
│       └── sshr.zsh               # known_hosts cleanup helper
├── dot_zfunc/                      # Committed zsh completions and lazy adapters
│   ├── _actionlint                 # Static actionlint completion
│   ├── _age                        # Static age / age-keygen completion
│   ├── _aws                        # AWS CLI completion adapter
│   ├── _bash_cli_complete          # Lazy bash-style CLI completion bridge
│   ├── _direnv                     # Static direnv completion
│   ├── _eza                        # Static eza completion
│   ├── _terraform                  # Terraform completion adapter
│   ├── _tofu                       # OpenTofu completion adapter
│   ├── _terragrunt                 # Terragrunt completion adapter
│   └── _bao                        # OpenBao completion adapter
├── dot_config/
│   ├── ghostty/config             # Ghostty terminal configuration
│   ├── alacritty/alacritty.toml   # Alacritty terminal configuration
│   ├── starship.toml              # Starship prompt configuration
│   ├── sheldon/plugins.toml       # sheldon plugin configuration
│   └── zellij/config.kdl          # Zellij multiplexer configuration
├── dot_kube/
│   └── kubie.yaml                 # kubie (kubectl context manager) configuration
├── private_dot_ssh/
│   └── config.tmpl                # ~/.ssh/config (OrbStack include, 1Password agent)
└── .chezmoiscripts/               # Setup scripts auto-executed by chezmoi
    ├── run_onchange_after_macos.sh.tmpl # macOS: apply Brewfile when it changes
    ├── run_onchange_linux0_package.sh   # Linux: sudo-only OS package installs (base deps, HashiCorp repo, kubectl, openbao, pipx/python3.12)
    ├── run_onchange_linux1_tool.sh      # Linux: install development tools (no sudo)
    ├── run_onchange_linux2_terminal.sh  # Linux: install kitty (no sudo)
    ├── run_onchange_linux3_fonts.sh     # Linux: install UDEV Gothic fonts (no sudo)
    └── run_after_zsh_completions.sh     # Regenerate CLI-provided zsh completions
```

## Key Tools

| Category | Tools |
|----------|-------|
| Shell | zsh, [sheldon](https://github.com/rossmacarthur/sheldon), [starship](https://starship.rs/) |
| Terminal | [Ghostty](https://ghostty.org/) (macOS), [Alacritty](https://alacritty.org/) (Linux) |
| Multiplexer | [Zellij](https://zellij.dev/), tmux |
| Kubernetes | kubectl, [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd/), [kubie](https://github.com/sbstp/kubie), [k9s](https://k9scli.io/), helm, helmfile, krew |
| IaC | Terraform, Packer, Vault, Terragrunt, [Ansible](https://www.ansible.com/), [ansible-lint](https://ansible.readthedocs.io/projects/lint/) |
| Cloud / S3 | [AWS CLI](https://aws.amazon.com/cli/) (v2; S3-compatible storage such as SeaweedFS) |
| Containers | [Podman](https://podman.io/) (Linux) |
| Other | [GitHub CLI](https://cli.github.com/), [bat](https://github.com/sharkdp/bat), [ripgrep](https://github.com/BurntSushi/ripgrep), [procs](https://github.com/dalance/procs), [DNSControl](https://dnscontrol.org/), [direnv](https://direnv.net/), [fzf](https://github.com/junegunn/fzf), [eza](https://github.com/eza-community/eza), [zoxide](https://github.com/ajeetdsouza/zoxide), SOPS |

## zsh Loading Strategy

To keep startup fast, [zsh-defer](https://github.com/romkatv/zsh-defer) splits configuration loading into two phases:

- `dot_zsh.d/source/` — loaded immediately at startup (e.g. completion path setup that cannot be deferred)
- `dot_zsh.d/defer/` — lazily loaded in the background (aliases, tool initializations)

### Completion Management

Shell startup must not invoke a CLI to generate or register completions. Completion
definitions are exposed through `~/.zfunc` and loaded by zsh only when completion is
used.

- If a CLI can output a zsh completion definition (for example,
  `sops completion zsh`), add it to
  `.chezmoiscripts/run_after_zsh_completions.sh`. The script regenerates the
  corresponding `~/.zfunc/_<command>` after `chezmoi apply`, and only replaces
  the file when its content changed. Generated output is normalized for zsh
  autoloading: `#compdef` must be the first line, and a generator that defines
  a differently named entrypoint must pass that function name to
  `generate_completion`. The generation script invalidates `.zcompdump` so the
  next shell discovers additions and changes.
- If a CLI has no completion generator, commit its completion definition or a
  lazy adapter under `dot_zfunc/`. Bash-style `complete -C` integrations use
  `_bash_cli_complete`, which defers `bashcompinit` and the CLI invocation until
  the first completion request.
- Do not run completion generators from `dot_zsh.d/source/`,
  `dot_zsh.d/defer/`, or `dot_zshrc`.

The post-apply script currently generates completions for Sheldon, Starship,
Zellij, Helm, Argo CD, Kubie, K9s, Helmfile, k0sctl, Cilium, GitHub CLI, bat,
ripgrep, procs, SOPS, DNSControl, Rclone, Ansible, and ansible-lint. The Linux
installer exposes Ansible's `register-python-argcomplete` dependency solely for
this generation step.

Static definitions are committed for actionlint, age/age-keygen,
ansible-playbook, direnv, and eza. AWS CLI, Terraform, OpenTofu, Terragrunt,
and OpenBao use lazy adapters.
fzf completion selection is already provided by the Sheldon-managed fzf-tab
plugin. Krew has no separate completion generator; kubectl handles discovery of
the `krew` plugin itself.

## Chezmoi Policy

Chezmoi templates are avoided unless the rendered file content must differ by OS, host, architecture, or secret data. Prefer normal shell/runtime guards for simple portability.

Repository-only files such as `README.md`, `bootstrap.sh`, `renovate.json`, and `docs/` are excluded from the target home directory via `.chezmoiignore`.
