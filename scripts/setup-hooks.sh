#!/usr/bin/env bash
# Install a local pre-commit hook that runs the canonical repo check.
# Usage: bash scripts/setup-hooks.sh [--force]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_DIR="$REPO_ROOT/.git/hooks"
HOOK_PATH="$HOOK_DIR/pre-commit"
MANAGED_MARKER="# micro-lab-template pre-commit hook"
FORCE=false

# shellcheck source=_lib.sh
source "$SCRIPT_DIR/_lib.sh"

usage() {
  cat <<USAGE
Usage: bash scripts/setup-hooks.sh [--force]

Options:
  --force     Replace an existing pre-commit hook
  -h, --help  Show this help
USAGE
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=true; shift ;;
    -h|--help) usage 0 ;;
    *) die "Unknown argument: $1" ;;
  esac
done

[[ -d "$REPO_ROOT/.git" ]] || die "Git metadata directory not found: $REPO_ROOT/.git"
mkdir -p "$HOOK_DIR"

if [[ -f "$HOOK_PATH" ]] && ! grep -Fq "$MANAGED_MARKER" "$HOOK_PATH"; then
  if [[ "$FORCE" != true ]]; then
    die "Existing pre-commit hook found at $HOOK_PATH. Re-run with --force to replace it."
  fi
  warn "Replacing existing pre-commit hook at $HOOK_PATH"
fi

cat > "$HOOK_PATH" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
# micro-lab-template pre-commit hook

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

bash scripts/selftest.sh all
HOOK

chmod +x "$HOOK_PATH"

info "Installed pre-commit hook: $HOOK_PATH"
info "The hook runs: bash scripts/selftest.sh all"
