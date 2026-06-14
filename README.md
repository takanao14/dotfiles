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
├── dot_zshrc                      # ~/.zshrc
├── dot_zprofile                   # ~/.zprofile (Homebrew path config)
├── dot_tmux.conf                  # ~/.tmux.conf
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
│       ├── terraform.zsh          # Terraform completion
│       ├── terragrunt.zsh         # Terragrunt completion
│       ├── krew.zsh               # kubectl krew path
│       └── sshr.zsh               # known_hosts cleanup helper
├── dot_config/
│   ├── ghostty/config             # Ghostty terminal configuration
│   ├── alacritty/alacritty.toml   # Alacritty terminal configuration
│   ├── starship.toml              # Starship prompt configuration
│   ├── sheldon/plugins.toml       # sheldon plugin configuration
│   └── zellij/config.kdl          # Zellij multiplexer configuration
├── dot_kube/
│   └── kubie.yaml                 # kubie (kubectl context manager) configuration
└── .chezmoiscripts/               # Setup scripts auto-executed by chezmoi
    ├── run_onchange_after_macos.sh.tmpl # macOS: apply Brewfile when it changes
    ├── run_onchange_linux1_tool.sh # Linux: install development tools
    ├── run_onchange_linux2_terminal.sh # Linux: install kitty
    └── run_onchange_linux3_fonts.sh # Linux: install UDEV Gothic fonts
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
| Other | [DNSControl](https://dnscontrol.org/), [direnv](https://direnv.net/), [fzf](https://github.com/junegunn/fzf), [eza](https://github.com/eza-community/eza), [zoxide](https://github.com/ajeetdsouza/zoxide), SOPS |

## zsh Loading Strategy

To keep startup fast, [zsh-defer](https://github.com/romkatv/zsh-defer) splits configuration loading into two phases:

- `dot_zsh.d/source/` — loaded immediately at startup (e.g. completion path setup that cannot be deferred)
- `dot_zsh.d/defer/` — lazily loaded in the background (aliases, tool initializations)

## Chezmoi Policy

Chezmoi templates are avoided unless the rendered file content must differ by OS, host, architecture, or secret data. Prefer normal shell/runtime guards for simple portability.

Repository-only files such as `README.md`, `bootstrap.sh`, and `renovate.json` are excluded from the target home directory via `.chezmoiignore`.
