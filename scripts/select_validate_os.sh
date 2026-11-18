#!/usr/bin/env bash
# Print the JSON list of runner OSes that must run scripts/validate.py for the
# changes between the merge base of BASE and HEAD.
#
# macOS validation is skipped only when every changed path is Linux-only or
# documentation. Any unknown path, an empty diff, or a missing base selects
# every OS, so new files are validated on macOS by default.
#
# Usage: select_validate_os.sh [BASE [HEAD]]
set -euo pipefail

readonly ALL='["ubuntu-26.04","macos-latest"]'
readonly LINUX='["ubuntu-26.04"]'

base="${1:-origin/main}"
head="${2:-HEAD}"

linux_only() {
  case "$1" in
    # Targets excluded from macOS by .chezmoiignore.
    dot_config/mise/* | dot_config/systemd/* | dot_config/kitty/*) return 0 ;;
    # Setup scripts that only run on Linux.
    .chezmoiscripts/run_*_linux_*) return 0 ;;
    # Documentation is neither rendered nor executed.
    *.md | docs/*) return 0 ;;
  esac
  return 1
}

if ! merge_base="$(git merge-base "$base" "$head" 2>/dev/null)"; then
  echo "No merge base for $base and $head; validating every OS." >&2
  echo "$ALL"
  exit 0
fi

changed=0
while IFS= read -r -d '' path; do
  changed=1
  if ! linux_only "$path"; then
    echo "macOS validation required by: $path" >&2
    echo "$ALL"
    exit 0
  fi
done < <(git diff --name-only -z "$merge_base" "$head")

if (( ! changed )); then
  echo "No changes since $merge_base; validating every OS." >&2
  echo "$ALL"
  exit 0
fi

echo "Only Linux-only paths changed; skipping macOS validation." >&2
echo "$LINUX"
