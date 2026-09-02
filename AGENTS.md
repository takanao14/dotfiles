# AGENTS.md

## Project

- This repository manages personal dotfiles with chezmoi.
- Support macOS and Linux: Ubuntu, Debian, and Rocky Linux.
- Prioritize portability, fast shell startup, maintainability, and few
  dependencies.

## Development Rules

- Communicate with the user in Japanese. Use English in code, comments, file
  names, commit messages, and documentation.
- Edit chezmoi source files, not rendered files in the home directory.
- Prefer plain source files. Use chezmoi templates only for OS, host,
  architecture, or secret-specific content; use runtime guards for simple
  portability.
- Keep every supported platform working. Guard optional commands with an
  availability check and avoid GNU- or BSD-specific flags without a compatible
  fallback.
- Put only startup-critical or ordering-sensitive zsh configuration in
  `dot_zsh.d/source/`; defer nonessential integrations through
  `dot_zsh.d/defer/`.
- Never invoke a CLI completion generator during shell startup. Add supported
  generators to `.chezmoiscripts/run_after_zsh_completions.sh`; use committed
  definitions or lazy adapters under `dot_zfunc/` when no generator exists.
- Keep setup scripts idempotent. An unchanged `chezmoi apply` must not
  repeatedly download tools, rewrite files, or restart services.
- Keep SSH configuration under `private_dot_ssh/` and preserve private target
  permissions.
- Never hardcode, commit, or print secrets. Keep secret-specific behavior in
  templates or environment integrations without exposing resolved values.
- Inspect the relevant script and platform guard before changing package or
  setup behavior.
- Show the user commands for machine-wide installation, service changes,
  `chezmoi apply`, and other state-changing machine operations; the user runs
  those commands.

## Validation

- For templates or rendered configuration, run `chezmoi execute-template` or
  `chezmoi diff`. Syntax-check rendered output rather than templates containing
  unevaluated chezmoi directives.
- For new managed files, run `chezmoi managed` to confirm source-to-target
  mapping.
- Run `zsh -n` for changed zsh files and `bash -n` for changed Bash scripts.
  Run `shellcheck` when it is available and applicable.
- Run `git diff --check` before handing off changes.
- Do not run validation that installs packages, accesses secrets, or changes
  the current machine without explicit authorization.

## Documentation and Naming

- Update `README.md` and this file when repository structure or operating
  conventions change.
- List repository-only files in `.chezmoiignore`.
- Use English names and ASCII filenames.
