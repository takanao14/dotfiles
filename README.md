# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports macOS and Linux (Ubuntu / Debian / Rocky Linux).

Linux x64 and arm64 are supported, including arm64 VMs on Apple Silicon.

Linux tool installation requires Python 3.12 or newer for the pinned Ansible
toolchain. Use a release or configured package repository that provides
`python3.12` when the distribution default is older.

## Setup

```bash
curl -fsSL https://raw.githubusercontent.com/takanao14/dotfiles/main/bootstrap.sh | bash
```

`bootstrap.sh` automatically runs the following:

1. Install Homebrew (macOS) / git, make, and zsh (Linux)
2. Install chezmoi
3. Apply this repository via `chezmoi init --apply takanao14/dotfiles`

## Structure

```
dotfiles/
├── bootstrap.sh                   # Setup script for new machines
├── dot_Brewfile                   # Homebrew package list (macOS)
├── dot_gitconfig.tmpl             # ~/.gitconfig (email templated per machine)
├── dot_zshrc                      # ~/.zshrc
├── modify_dot_bashrc              # Appends the shared PATH setup to ~/.bashrc (Linux)
├── dot_zprofile                   # ~/.zprofile (Homebrew path config)
├── dot_tmux.conf                  # ~/.tmux.conf
├── dot_vimrc                      # ~/.vimrc (portable Vim defaults)
├── .chezmoi.toml.tmpl             # chezmoi data (1Password detection, prompted email)
├── dot_zsh.d/
│   ├── source/                    # Loaded immediately at zsh startup
│   │   ├── cargo.zsh              # Cargo and Homebrew rustup paths
│   │   ├── editor.zsh             # Editor environment variable
│   │   ├── empty_null.zsh          # Sheldon source placeholder
│   │   ├── env.zsh                # ~/.env loader
│   │   ├── fpath.zsh              # Completion path configuration
│   │   ├── go.zsh                 # Go installation path
│   │   ├── ssh.zsh                # SSH TERM fallback for kitty
│   │   ├── ssh_agent.zsh          # Forwarded/local SSH agent selection
│   │   └── starship.zsh           # Starship prompt initialization
│   └── defer/                     # Lazily loaded via zsh-defer
│       ├── alias.zsh              # Aliases (kubectl, etc.)
│       ├── direnv.zsh             # direnv hook
│       ├── empty_null.zsh          # Sheldon defer placeholder
│       ├── idea.zsh               # IntelliJ IDEA command path
│       ├── krew.zsh               # kubectl krew path
│       ├── opencode.zsh            # OpenCode command path
│       ├── orbstack.zsh           # OrbStack shell init (Linux VMs)
│       ├── sops.zsh               # SOPS age key environment variable
│       ├── sshr.zsh               # known_hosts cleanup helper
│       ├── yazi.zsh               # Yazi wrapper with change-directory support
│       └── zoxide.zsh             # zoxide initialization
├── dot_zfunc/                      # Committed zsh completions and lazy adapters
│   ├── _actionlint                 # Static actionlint completion
│   ├── _age                        # Static age / age-keygen completion
│   ├── _aws                        # AWS CLI completion adapter
│   ├── _bash_cli_complete          # Lazy bash-style CLI completion bridge
│   ├── _btm                        # Static bottom completion
│   ├── _hyperfine                  # Static hyperfine completion
│   ├── _direnv                     # Static direnv completion
│   ├── _dust                       # Static dust completion
│   ├── _eza                        # Static eza completion
│   ├── _ya                         # Static Yazi CLI completion
│   ├── _yazi                       # Static Yazi completion
│   ├── _terraform                  # Terraform completion adapter
│   ├── _packer                     # Packer completion adapter
│   ├── _vault                      # Vault completion adapter
│   ├── _zoxide                     # Static zoxide CLI completion
│   ├── _tofu                       # OpenTofu completion adapter
│   ├── _terragrunt                 # Terragrunt completion adapter
│   └── _bao                        # OpenBao completion adapter
├── dot_config/
│   ├── ghostty/config             # Ghostty terminal configuration
│   ├── alacritty/alacritty.toml   # Alacritty terminal configuration
│   ├── kitty/kitty.conf           # Kitty configuration (Linux desktop only)
│   ├── mise/config.toml           # Linux CLI tool declarations (user and golden image)
│   ├── mise/mise.lock             # Resolved Linux artifacts for x64 and arm64
│   ├── shell/path.sh              # PATH and mise shims shared by zsh and bash
│   ├── systemd/user/ssh-agent.service # Linux local SSH agent fallback
│   ├── starship.toml              # Starship prompt configuration
│   ├── sheldon/plugins.toml       # sheldon plugin configuration
│   └── zellij/config.kdl          # Zellij multiplexer configuration
├── dot_kube/
│   └── kubie.yaml                 # kubie (kubectl context manager) configuration
├── private_dot_ssh/
│   └── config.tmpl                # ~/.ssh/config (OrbStack include, 1Password agent)
└── .chezmoiscripts/               # Setup scripts auto-executed by chezmoi, in name order
    ├── run_onchange_10_linux_package.sh # Linux: sudo-only OS package installs (base deps, HashiCorp repo, kubectl, openbao, Freelens on desktops, python3.12)
    ├── run_onchange_20_linux_terminal.sh # Linux: install kitty (no sudo)
    ├── run_onchange_30_linux_fonts.sh   # Linux: install UDEV Gothic fonts (no sudo)
    ├── run_onchange_after_40_linux_mise.sh.tmpl # Linux: install mise and the pinned tools
    ├── run_onchange_after_50_linux_ssh_agent.sh.tmpl # Linux: enable the ssh-agent user unit
    ├── run_onchange_after_60_macos_brew.sh.tmpl # macOS: apply Brewfile when it changes
    └── run_after_70_all_zsh_completions.sh # Regenerate CLI-provided zsh completions
```

Scripts are named `run_[onchange_][after_]<NN>_<platform>_<topic>.sh`. chezmoi
runs unprefixed scripts during the apply and `after_` scripts once every file is
in place, sorting each group by the name left after the `run_`, `onchange_` and
`after_` prefixes are stripped. `<NN>` is therefore the only ordering control,
and it runs as a single sequence across both platforms and both phases: mise
needs its deployed config, so it is `after_`, and completion generation must see
the installed tools, so it is last.

## Key Tools

| Category | Tools |
|----------|-------|
| Shell | zsh, [sheldon](https://github.com/rossmacarthur/sheldon), [starship](https://starship.rs/) |
| Terminal | [Ghostty](https://ghostty.org/) (macOS), [Kitty](https://sw.kovidgoyal.net/kitty/) (Linux desktop), [Alacritty](https://alacritty.org/) (configuration only) |
| File manager | [Yazi](https://yazi-rs.github.io/) |
| Multiplexer | [Zellij](https://zellij.dev/), tmux |
| Kubernetes | kubectl, [Freelens](https://freelens.app/) (desktop machines), [Argo CD CLI](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd/), [kubie](https://github.com/sbstp/kubie), [k9s](https://k9scli.io/), helm, helmfile, krew |
| IaC | Terraform, Packer, Vault, Terragrunt, [Ansible](https://www.ansible.com/), [ansible-lint](https://ansible.readthedocs.io/projects/lint/) |
| Cloud / S3 | [AWS CLI](https://aws.amazon.com/cli/) (v2; S3-compatible storage such as SeaweedFS) |
| Containers | [Podman](https://podman.io/) (Linux) |
| Other | [GitHub CLI](https://cli.github.com/), [bat](https://github.com/sharkdp/bat), [fd](https://github.com/sharkdp/fd), [delta](https://github.com/dandavison/delta), [hyperfine](https://github.com/sharkdp/hyperfine), [bottom](https://github.com/ClementTsang/bottom), [ripgrep](https://github.com/BurntSushi/ripgrep), [dust](https://github.com/bootandy/dust), [dua-cli](https://github.com/Byron/dua-cli), [DNSControl](https://dnscontrol.org/), [direnv](https://direnv.net/), [fzf](https://github.com/junegunn/fzf), [eza](https://github.com/eza-community/eza), [zoxide](https://github.com/ajeetdsouza/zoxide), SOPS |

Git uses delta as its pager when available and falls back to less. Delta uses
a unified diff layout with section navigation; side-by-side output is opt-in.
Use `ps` and `pgrep` for process lookup, `btm` for live system monitoring,
and `hyperfine` for repeatable command benchmarks.

Run `yazi` to browse files, or `y` in zsh to also change the shell directory
on exit. Yazi uses the existing `file`, fd, ripgrep, fzf, and zoxide tools.
Additional media preview tools and plugins are optional and are not managed
by this configuration.

On Linux, APT or DNF packages are installed globally, while standalone CLI
tools use versions pinned in `~/.config/mise/config.toml` and are installed per
user by default. `mise.lock` resolves those versions to checksummed Linux x64
and arm64 artifacts, and setup uses `mise install --locked` to avoid live
release resolution. `minimum_release_age = "2d"` and `UV_EXCLUDE_NEWER` keep
the Python dependencies that uv resolves for the `pipx:` tools at least two days
old, matching Renovate's `minimumReleaseAge`. Golden images use the same config
and lockfile with mise system mode under `/usr/local/share/mise`. The shell
prefers user shims, allowing a project mise config to override the system
baseline. Renovate updates the configured versions; the `mise-lock` GitHub
Actions workflow refreshes both the bootstrap binary checksums and lockfile on
the same branch. mise version updates remain manual-review-only. macOS continues to use Homebrew's rolling package model.

macOS installs UDEV Gothic NF through the Brewfile, while Linux desktop
machines install the same font through the font setup script.

## zsh Loading Strategy

To keep startup fast, [zsh-defer](https://github.com/romkatv/zsh-defer) splits configuration loading into two phases:

Deferred tasks skip per-task prompt redraws; otherwise each task can trigger
another Starship render during the first prompt.

- `dot_zsh.d/source/` — loaded immediately at startup (e.g. completion path setup that cannot be deferred)
- `dot_zsh.d/defer/` — lazily loaded in the background (aliases, tool initializations)

### Completion Management

Shell startup must not invoke a CLI to generate or register completions. Completion
definitions are exposed through `~/.zfunc` and loaded by zsh only when completion is
used.

- If a CLI can output a zsh completion definition (for example,
  `sops completion zsh`), add it to
  `.chezmoiscripts/run_after_70_all_zsh_completions.sh`. The script regenerates the
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

The post-apply script currently generates completions for mise, chezmoi, yq,
dua, lazygit, Sheldon, Starship,
Zellij, Helm, Argo CD, Kubie, K9s, Helmfile, k0sctl, Cilium, GitHub CLI, bat,
fd, delta, ripgrep, SOPS, DNSControl, Rclone, uv, and ansible-lint. It also
generates Ansible and ansible-playbook completions when zsh does not provide
them. `argcomplete` is declared in the mise config so
`register-python-argcomplete` exists for the Ansible generators. When zsh
provides `_ansible` for both Ansible and ansible-playbook, the script uses it
and removes only its own older generated definitions. Otherwise, it generates
completions for those commands. If a command cannot import `argcomplete` from
its own Python environment, the generated completion reads its `--help` options
on completion requests and completes files for positional arguments. Ansible-lint
uses the same generator or fallback independently.

Static definitions are committed for actionlint, age/age-keygen,
direnv, dust, eza, hyperfine, bottom (`btm`), zoxide, and Yazi (`yazi` / `ya`).
The hyperfine, bottom, Yazi, dust, and zoxide definitions come from their pinned
upstream releases or source tags. The zoxide CLI definition is separate from
the existing `z` / `zi` shell integration.
AWS CLI, Terraform, OpenTofu, Terragrunt, OpenBao, Packer, and Vault use lazy adapters.
fzf completion selection is already provided by the Sheldon-managed fzf-tab
plugin. Krew has no separate completion generator; kubectl handles discovery of
the `krew` plugin itself.

## Chezmoi Policy

Chezmoi templates are avoided unless the rendered file content must differ by OS, host, architecture, or secret data. Prefer normal shell/runtime guards for simple portability.

Linux machines have an explicit `desktop` or `server` profile stored in the
chezmoi data and exported to scripts as `TOOL_MACHINE_PROFILE`. Kitty, UDEV
Gothic and Freelens are installed only for the desktop profile, and the Kitty
configuration is managed there as `~/.config/kitty/kitty.conf`. Standalone and
golden-image installers use the same environment-variable contract and the
root-owned `/etc/provisioning/machine-profile.local` image marker. An unset
profile with no marker defaults to `server`; live GUI state is deliberately not
inferred.

Repository-only files such as `README.md`, `bootstrap.sh`, `renovate.json`, and `docs/` are excluded from the target home directory via `.chezmoiignore`.

## Development and main protection

Push changes to a branch and open a PR; owners and bots follow the same rules.
Non-major Renovate updates merge only after the latest commit passes CI (mise
version updates still require a manual merge). `Dotfiles CI` runs on every PR
without path filters. Validation waits for mise generation, then checks the exact
resulting commit on macOS and Linux. A generated push explicitly dispatches
validation on the update branch because `GITHUB_TOKEN` PR events need workflow
approval. The result job records `Dotfiles CI` on the exact validated SHA;
dispatch check suites alone are not included in the PR status rollup, and a
token-dispatched run does not trigger a subsequent `workflow_run`. A trusted
`workflow_run` publisher handles read-only fork validation without executing PR
code. Run **Refresh mise lockfile manually** to create a separate branch and
PR, even when selecting `main`; an unchanged refresh creates no PR.

Local validation (Python 3.11+, chezmoi, zsh, Bash, ShellCheck):

```sh
python3 scripts/validate.py
actionlint
```

Validation renders both architectures and Linux machine profiles using synthetic
data and a temporary destination. It syntax-checks shell sources, completions
and rendered scripts, checks TOML/JSON and target exclusions, and never applies
dotfiles or runs setup scripts. The OS package managers and services themselves
are not exercised by local validation. The mise lock validator checks configured
versions and requires both Linux platform entries for every platform-specific
tool; `pipx:` tools have platform-independent locks.

Required CI also installs every declared mise tool with `--locked` on fresh
Ubuntu x64 and arm64 runners and checks that bottom and k9s start. This does
not replace a first and repeated `chezmoi apply` on a disposable stock Linux
VM, or runtime verification on Debian and Rocky Linux. Those checks cover OS
packages, services, setup ordering, and idempotence beyond the mise install.

For a new repository, merge the CI PR first, verify an ordinary PR and a generated
commit's **Dotfiles CI** check, then create a branch ruleset in Settings → Rules →
Rulesets: target `refs/heads/main`, enforcement **Active**, bypass list **empty**,
restrict deletions, block force pushes, require a PR with **0** approvals, and
require **Dotfiles CI** from GitHub Actions with **Require branches to be up to
date** enabled. Use the payload in `docs/main-ruleset.json` with
`gh api --method POST repos/OWNER/REPO/rulesets --input docs/main-ruleset.json`.
Read back the active ruleset before deleting the old `main` branch protection
(`gh api --method DELETE repos/OWNER/REPO/branches/main/protection`). This short
overlap preserves deletion/force-push protection during migration. Do not enable
the required check before it exists and succeeds on the latest generated SHA.
